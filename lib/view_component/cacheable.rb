# frozen_string_literal: true

require "view_component/cache_registry"
require "view_component/cache_digestor"

module ViewComponent::Cacheable
  extend ActiveSupport::Concern

  included do
    class_attribute :__vc_cache_dependencies, default: Set.new

    # For caching, such as #cache_if
    #
    # @private
    def view_cache_dependencies
      self.class.__vc_cache_dependencies.map { |dep| public_send(dep) }
    end

    def view_cache_options
      return if self.class.__vc_cache_dependencies.blank?

      template_key = __vc_cache_template_key
      return if template_key.nil?

      cache_key_parts = [self.class.name, self.class.virtual_path, template_key, view_cache_dependencies, component_digest]
      combined_fragment_cache_key(ActiveSupport::Cache.expand_cache_key(cache_key_parts))
    end

    # Render component from cache if possible
    #
    # @private
    def __vc_render_cacheable(safe_call)
      if view_cache_options
        ViewComponent::CachingRegistry.track_caching do
          template_fragment(safe_call)
        end
      else
        instance_exec(&safe_call)
      end
    end

    # @private
    def __vc_cache_template_key
      return unless defined?(@current_template) && @current_template

      [@current_template.call_method_name, @current_template.virtual_path]
    end

    def template_fragment(safe_call)
      if (content = read_fragment)
        @view_renderer.cache_hits[@current_template&.virtual_path] = :hit if defined?(@view_renderer)
        content
      else
        @view_renderer.cache_hits[@current_template&.virtual_path] = :miss if defined?(@view_renderer)
        write_fragment(safe_call)
      end
    end

    def read_fragment
      Rails.cache.fetch(view_cache_options)
    end

    def write_fragment(safe_call)
      content = instance_exec(&safe_call)
      Rails.cache.fetch(view_cache_options) do
        content
      end
      content
    end

    def combined_fragment_cache_key(key)
      cache_key = [:view_component, ENV["RAILS_CACHE_ID"] || ENV["RAILS_APP_VERSION"], key]
      cache_key.flatten!(1)
      cache_key.compact!
      cache_key
    end

    def component_digest
      ViewComponent::CacheDigestor.new(component: self).digest
    end
  end

  class_methods do
    # For caching the component
    def cache_on(*args)
      __vc_cache_dependencies.merge(args)
    end

    def inherited(child)
      child.__vc_cache_dependencies = __vc_cache_dependencies.dup

      super
    end
  end
end
