# frozen_string_literal: true

require "digest"
require "view_component/template_dependency_extractor"

module ViewComponent
  class CacheDigestor
    def initialize(component:)
      @component = component
      @visited_components = {}
      @digests = {}
    end

    def digest
      digest_for_component(@component.class)
    end

    private

    TEMPLATE_EXTENSIONS = %w[erb haml slim].freeze
    private_constant :TEMPLATE_EXTENSIONS

    def digest_for_component(component_class)
      return "" unless component_class.respond_to?(:name)
      return "" unless component_class <= ViewComponent::Base

      cached_digest = @digests[component_class.name]
      return cached_digest if cached_digest

      return "" if @visited_components.key?(component_class.name)

      @visited_components[component_class.name] = true

      sources = []

      identifier = component_class.identifier
      sources << file_contents(identifier) if identifier

      inline_template = component_class.__vc_inline_template if component_class.respond_to?(:__vc_inline_template)
      if inline_template
        sources << inline_template.source

        dependencies = ViewComponent::TemplateDependencyExtractor.new(inline_template.source, inline_template.language).extract
        sources.concat(dependency_digests(dependencies))
      end

      component_class.sidecar_files(TEMPLATE_EXTENSIONS).sort.each do |path|
        template_source = file_contents(path)
        next unless template_source

        sources << template_source

        handler = path.split(".").last
        dependencies = ViewComponent::TemplateDependencyExtractor.new(template_source, handler).extract
        sources.concat(dependency_digests(dependencies))
      end

      component_class.sidecar_files(["yml"]).sort.each do |path|
        sources << file_contents(path)
      end

      @digests[component_class.name] = Digest::SHA1.hexdigest(sources.compact.join("\n"))
    end

    def dependency_digests(dependencies)
      dependencies.filter_map do |dep|
        next unless dep.match?(/\A[A-Z]/)

        klass = constantize(dep)
        next unless klass

        digest_for_component(klass)
      end
    end

    def constantize(constant_name)
      constant_name.split("::").reduce(Object) do |namespace, name|
        namespace.const_get(name)
      end
    rescue NameError
      nil
    end

    def file_contents(path)
      return unless path
      return unless File.file?(path)

      File.read(path)
    end
  end
end
