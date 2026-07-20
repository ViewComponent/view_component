# frozen_string_literal: true

require "digest"
require "view_component/template_dependency_extractor"

module ViewComponent
  class CacheDigestor
    def self.digest(component)
      new(component: component).digest
    end

    def initialize(component:)
      @component_class = component.is_a?(Class) ? component : component.class
      @digests = {}
      @file_cache = {}
      @constant_cache = {}
    end

    def digest
      digest_for_component(@component_class)
    end

    private

    # Prevents infinite recursion when components render each other cyclically.
    IN_PROGRESS = :__vc_in_progress
    private_constant :IN_PROGRESS

    def digest_for_component(component_class)
      return "" unless component_class <= ViewComponent::Base
      name = component_class.name || component_class.object_id

      cached_digest = @digests[name]
      return "" if cached_digest == IN_PROGRESS
      return cached_digest if cached_digest

      @digests[name] = IN_PROGRESS

      digest = Digest::SHA1.new

      update_digest(digest, cached_file_contents(component_class.identifier))

      inline_template = component_class.__vc_inline_template
      if inline_template
        inline_source = inline_template.source
        update_digest(digest, inline_source)
        update_template_dependency_digests(digest, inline_source, inline_template.language, component_class.identifier)
      end

      component_class.sidecar_templates.sort.each do |path|
        template_source = cached_file_contents(path)
        update_digest(digest, template_source)
        update_template_dependency_digests(digest, template_source, File.extname(path).delete_prefix("."), path)
      end

      component_class.sidecar_translations.sort.each do |path|
        update_digest(digest, cached_file_contents(path))
      end

      @digests[name] = digest.hexdigest
    end

    def update_template_dependency_digests(digest, template_source, handler, identifier)
      return unless template_source&.include?("render")

      dependencies = ViewComponent::TemplateDependencyExtractor.new(template_source, handler, identifier: identifier).extract
      update_dependency_digests(digest, dependencies)
    end

    def update_dependency_digests(digest, dependencies)
      dependencies.each do |dep|
        next unless uppercase_constant?(dep)

        klass = cached_constantize(dep)
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

    def cached_constantize(constant_name)
      @constant_cache.fetch(constant_name) do
        @constant_cache[constant_name] = constant_name.safe_constantize
      end
    end

    def cached_file_contents(path)
      return nil if path.nil?

      @file_cache.fetch(path) do
        @file_cache[path] = File.file?(path) ? File.read(path) : nil
      end
    end
  end
end
