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

      # `# Template Dependency: foo/bar` comments in a component's Ruby file, the
      # escape hatch for dependencies static analysis can't see.
      EXPLICIT_DEPENDENCY = /#\s*Template Dependency:\s*(\S+)/

      class << self
        def instance
          @instance ||= new
        end
      end

      def find_templates(name, prefix, partial, details, locals = [])
        virtual_path = [prefix.presence, name].compact.join("/")
        component = CacheDigest.component_for(virtual_path)
        return [] unless component

        [build_template(component, virtual_path, details)]
      rescue
        # Never let digest resolution break rendering. Returning no template
        # makes the Digestor treat this as a missing node, which degrades to
        # the behavior components have without this feature.
        []
      end

      def to_s
        "ViewComponent::CacheDigest::Resolver"
      end
      alias_method :to_path, :to_s

      def eql?(other)
        self.class.equal?(other.class)
      end
      alias_method :==, :eql?

      private

      def build_template(component, virtual_path, details)
        ActionView::Template.new(
          source_for(component),
          "view_component cache digest for #{component.name}",
          ActionView::Template.handler_for_extension(:erb),
          locals: [],
          format: Array(details[:formats]).first || :html,
          virtual_path: virtual_path
        )
      end

      # The synthetic source. Every section exists to change this string when
      # something the component renders from changes.
      def source_for(component)
        parts = []

        # Safety net: this template should never be rendered, only digested.
        parts << "<% raise ViewComponent::CacheDigestTemplateError.new(#{component.name.inspect}) %>"

        # Content hashes of the Ruby files and sidecar files backing the
        # component and its component superclasses. Hashing rather than
        # inlining keeps the source small and avoids embedding Ruby that a
        # tracker might misread as a render call.
        source_files(component).each do |path|
          parts << "<%# Resolved Dependency: #{path} #{file_digest(path)} %>"
        end

        # Dependencies declared with `# Template Dependency:` in the component's
        # Ruby file. Re-emitted so the Digestor resolves them as tree nodes.
        explicit_dependencies(component).each do |dependency|
          parts << "<%# Template Dependency: #{dependency} %>"
        end

        # Template sources verbatim, so trackers can discover the partials and
        # components they render.
        template_sources(component).each do |source|
          parts << source
        end

        parts.join("\n")
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

      def source_files(component)
        component_ancestors(component).flat_map { |ancestor|
          [ancestor.identifier, *ancestor.sidecar_files(SIDECAR_EXTENSIONS)]
        }.compact.uniq.select { |path| ::File.exist?(path) }
      end

      def template_files(component)
        component_ancestors(component)
          .flat_map { |ancestor| ancestor.sidecar_files(ActionView::Template::Handlers.extensions) }
          .uniq
          .select { |path| ::File.exist?(path) }
      end

      def template_sources(component)
        template_files(component).map { |path| ::File.read(path) }
      end

      def explicit_dependencies(component)
        component_ancestors(component).flat_map { |ancestor|
          path = ancestor.identifier
          next [] unless path && ::File.exist?(path)

          ::File.read(path).scan(EXPLICIT_DEPENDENCY).flatten
        }.uniq
      end

      def file_digest(path)
        ActiveSupport::Digest.hexdigest(::File.read(path))
      end
    end
  end
end
