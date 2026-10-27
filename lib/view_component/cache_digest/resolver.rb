# frozen_string_literal: true

module ViewComponent
  module CacheDigest
    # Synthesizes the templates Rails' `ActionView::Digestor` digests components from.
    #
    # Once `DependencyTracking` reports `view_component/cache_digest/foo_component`
    # as a dependency, the Digestor tries to find a template at that path. No such
    # file exists: a component's rendered output depends on its template *and* its
    # Ruby class, its sidecar files, and its superclasses.
    #
    # This resolver answers with a synthetic template whose source encodes all of
    # those inputs. The template is never compiled or rendered; the Digestor only
    # reads `#source` to hash it and to scan it for further dependencies.
    #
    # @private
    class Resolver < ActionView::Resolver
      # Extensions whose contents are hashed into the synthetic source.
      SIDECAR_EXTENSIONS = %w[yml yaml].freeze

      # Where ViewComponent's own modules, such as the ones it includes into
      # every component, are defined.
      VIEW_COMPONENT_LIB = "#{::File.expand_path("..", __dir__)}/".freeze

      class << self
        def instance
          INSTANCE
        end
      end

      def find_templates(name, prefix, partial, details, locals = [])
        virtual_path = [prefix.presence, name].compact.join("/")
        component = CacheDigest.component_for(virtual_path)
        return [] unless component

        [build_template(component, virtual_path, details)]
      end

      def to_s
        "ViewComponent::CacheDigest::Resolver"
      end
      alias_method :to_path, :to_s

      def eql?(other)
        self.class.equal?(other.class)
      end
      alias_method :==, :eql?

      # The synthetic source. Every section exists to change this string when
      # something the component renders from changes.
      #
      # @param component [Class]
      # @return [String]
      def source_for(component)
        parts = []
        templates = template_sources(component)

        # Safety net: this template should never be rendered, only digested.
        parts << "<% raise ViewComponent::CacheDigestTemplateError.new(#{component.name.inspect}) %>"

        # Content hashes of the Ruby files and sidecar files backing the
        # component, its component superclasses, and the modules they include.
        # Hashing rather than inlining keeps the source small and avoids
        # embedding Ruby that a tracker might misread as a render call.
        source_files(component).each do |path|
          parts << "<%# Resolved Dependency: #{path} #{file_digest(path)} %>"
        end

        # Everything the component renders: `# Template Dependency:`
        # declarations, the components its slots are declared with, and the
        # components and partials referenced from its templates, in any
        # language, and from its Ruby. Emitted as declarations so the Digestor
        # resolves them as tree nodes without trackers having to find them in
        # the template sources, where they'd also infer partials from component
        # renders.
        dependencies(component, templates).each do |dependency|
          parts << "<%# Template Dependency: #{dependency} %>"
        end

        # Content hashes of the templates, including inline ones.
        templates.each do |source, _extension|
          parts << "<%# Template Digest: #{ActiveSupport::Digest.hexdigest(source)} %>"
        end

        parts.join("\n")
      end

      private

      def build_template(component, virtual_path, details)
        source = component.__vc_cache_digest_source || CacheDigest.analyzing(:source, component) { source_for(component) }

        ActionView::Template.new(
          source,
          "view_component cache digest for #{component.name}",
          ActionView::Template.handler_for_extension(:erb),
          locals: [],
          format: Array(details[:formats]).first || :html,
          virtual_path: virtual_path
        )
      end

      # The component and any component superclasses, nearest first. Including
      # ancestors means editing `ApplicationComponent` invalidates every
      # component that inherits from it.
      def component_ancestors(component)
        component.ancestors.select do |ancestor|
          ancestor.is_a?(Class) &&
            ancestor <= ViewComponent::Base &&
            ancestor != ViewComponent::Base
        end
      end

      # Modules the component and its component superclasses include, such as
      # a module of helpers that render other components. Modules included
      # into `ViewComponent::Base` and above are left out, as superclasses
      # are, and so are the modules ViewComponent adds to every component.
      #
      # @return [Array<String>] the files the modules are defined in
      def module_files(component)
        component.ancestors.take_while { |ancestor| ancestor != ViewComponent::Base }.filter_map { |ancestor|
          next if ancestor.is_a?(Class) || ancestor.name.nil?

          path, _line = Object.const_source_location(ancestor.name)
          path unless path.nil? || path.start_with?(VIEW_COMPONENT_LIB)
        }.uniq
      end

      def source_files(component)
        component_ancestors(component).flat_map { |ancestor|
          [ancestor.identifier, *ancestor.__vc_sidecar_files(SIDECAR_EXTENSIONS)]
        }.concat(module_files(component)).compact.uniq.select { |path| ::File.exist?(path) }
      end

      def template_files(component)
        component_ancestors(component)
          .flat_map { |ancestor| ancestor.__vc_sidecar_files(ActionView::Template::Handlers.extensions) }
          .uniq
          .select { |path| ::File.exist?(path) }
      end

      # Sidecar template files plus inline templates, which live in the Ruby
      # file and so are invisible to Action View's trackers.
      #
      # @return [Array<Array(String, String)>] pairs of source and extension
      def template_sources(component)
        sources = template_files(component).map { |path| [::File.read(path), ::File.extname(path).delete_prefix(".")] }

        component_ancestors(component).each do |ancestor|
          inline_template = ancestor.__vc_inline_template
          sources << [inline_template.source, inline_template.language.to_s] if inline_template
        end

        sources.uniq
      end

      def explicit_dependencies(sources)
        sources.flat_map { |source|
          declared = source.scan(CacheDigest::EXPLICIT_DEPENDENCY).flatten

          # Component class names are translated to the path they're digested
          # under; anything else is a template path already.
          CacheDigest.explicit_component_dependencies(source).each do |name, virtual_path|
            declared = declared - [name] + [virtual_path]
          end

          declared
        }.uniq
      end

      # Everything but the component and its superclasses, which a component
      # references in its own source but are digested as part of it already.
      def dependencies(component, templates)
        virtual_path = CacheDigest.virtual_path_for(component)
        ruby = ruby_sources(component)
        own_paths = component_ancestors(component).filter_map { |ancestor| CacheDigest.virtual_path_for(ancestor) }

        dependencies = explicit_dependencies(ruby + templates.map(&:first)) |
          ruby.flat_map { |source| ruby_dependencies(source, virtual_path) } |
          CacheDigest.slot_renders_of(component) |
          templates.flat_map { |source, extension| template_dependencies(component, source, extension, virtual_path) }

        dependencies - own_paths
      end

      # Components and partials rendered from Ruby, such as a `#call` method.
      # Partials are narrowed to paths that appear in the source, discarding
      # the speculative `things/thing` Action View infers from dynamic renders
      # like `render @thing`, which would resolve to nothing.
      def ruby_dependencies(source, virtual_path)
        components, partials = CacheDigest.renders_in(source, virtual_path)

        components | partials.select { |path|
          source.include?(path) || source.include?(path.sub(%r{[^/]+\z}, '_\0'))
        }
      end

      def template_dependencies(component, source, extension, virtual_path)
        return [] unless source.include?("render")

        template = ActionView::Template.new(
          source,
          "view_component cache digest for #{component.name}",
          ActionView::Template.handler_for_extension(extension),
          locals: [],
          format: nil,
          virtual_path: virtual_path
        )
        CacheDigest.renders_in(CacheDigest.compiled_source(template), virtual_path).flatten
      end

      def ruby_sources(component)
        component_ancestors(component).map(&:identifier).concat(module_files(component)).uniq.filter_map { |path|
          ::File.read(path) if path && ::File.exist?(path)
        }
      end

      def file_digest(path)
        ActiveSupport::Digest.hexdigest(::File.read(path))
      end

      # Built once at load time rather than memoized, so no class-level state
      # is written after boot. Unless sources were precomputed at boot, the
      # resolver reads from disk on every call so it can't go stale when a
      # component changes.
      INSTANCE = new
    end
  end
end
