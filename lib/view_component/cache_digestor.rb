# frozen_string_literal: true

require "digest"
require "view_component/template_dependency_extractor"

module ViewComponent
  class CacheDigestor
    def initialize(component:)
      @component = component
      @digests = {}
      @file_cache = {}
      @constant_cache = {}
    end

    def digest
      digest_for_component(@component.class)
    end

    private

    TEMPLATE_EXTENSIONS = %w[erb haml slim].freeze
    private_constant :TEMPLATE_EXTENSIONS

    IN_PROGRESS = :__vc_in_progress
    private_constant :IN_PROGRESS

    def digest_for_component(component_class)
      name = component_class.name
      return "" unless name
      return "" unless component_class <= ViewComponent::Base

      cached_digest = @digests[name]
      return "" if cached_digest == IN_PROGRESS
      return cached_digest if cached_digest

      @digests[name] = IN_PROGRESS

      digest = Digest::SHA1.new

      if (identifier = component_class.identifier)
        update_digest(digest, file_contents(identifier))
      end

      inline_template = component_class.__vc_inline_template if component_class.respond_to?(:__vc_inline_template)
      if inline_template
        update_digest(digest, inline_template.source)

        dependencies = ViewComponent::TemplateDependencyExtractor.new(inline_template.source, inline_template.language).extract
        update_dependency_digests(digest, dependencies)
      end

      component_class.sidecar_files(TEMPLATE_EXTENSIONS).sort.each do |path|
        template_source = file_contents(path)
        next unless template_source

        update_digest(digest, template_source)

        handler = path.rpartition(".").last
        dependencies = ViewComponent::TemplateDependencyExtractor.new(template_source, handler).extract
        update_dependency_digests(digest, dependencies)
      end

      component_class.sidecar_files(["yml"]).sort.each do |path|
        update_digest(digest, file_contents(path))
      end

      @digests[name] = digest.hexdigest
    end

    def update_dependency_digests(digest, dependencies)
      dependencies.each do |dep|
        next unless uppercase_constant?(dep)

        klass = constantize(dep)
        next unless klass

        update_digest(digest, digest_for_component(klass))
      end
    end

    def update_digest(digest, value)
      return unless value

      digest.update(value)
      digest.update("\n")
    end

    def uppercase_constant?(dep)
      return false unless dep

      first = dep.getbyte(0)
      first && first >= 65 && first <= 90
    end

    def constantize(constant_name)
      @constant_cache.fetch(constant_name) do
        @constant_cache[constant_name] = constant_name.split("::").reduce(Object) { |namespace, name| namespace.const_get(name) }
      end
    rescue NameError
      @constant_cache[constant_name] = nil
    end

    def file_contents(path)
      @file_cache.fetch(path) do
        @file_cache[path] = File.file?(path) ? File.read(path) : nil
      end
    end
  end
end
