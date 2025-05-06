# frozen_string_literal: true

require 'set'
require 'view_component/cache_registry'

module ViewComponent::Cacheable
  extend ActiveSupport::Concern

  included do
    class_attribute :__vc_cache_dependencies, default: Set[:format, :__vc_format, :identifier]

    # For caching, such as #cache_if
    #
    # @private
    def view_cache_dependencies
      return if __vc_cache_dependencies.blank? || __vc_cache_dependencies.none? || __vc_cache_dependencies.nil?

      computed_view_cache_dependencies = __vc_cache_dependencies.map { |dep| if respond_to?(dep) then public_send(dep) end }
      combined_fragment_cache_key(ActiveSupport::Cache.expand_cache_key(computed_view_cache_dependencies))
    end

    # Render component from cache if possible
    #
    # @private
    def __vc_render_cacheable(rendered_template)
      if __vc_cache_dependencies != [:format, :__vc_format]
        ViewComponent::CachingRegistry.track_caching do
           template_fragment(rendered_template)
        end
      else
        __vc_render_template(rendered_template)
      end
    end

    def template_fragment(rendered_template)
      if content = read_fragment(rendered_template)
        @view_renderer.cache_hits[@current_template&.virtual_path] = :hit if defined?(@view_renderer)
        content
      else
        @view_renderer.cache_hits[@current_template&.virtual_path] = :miss if defined?(@view_renderer)
        write_fragment(rendered_template)
      end
    end

    def read_fragment(rendered_template)
      Rails.cache.fetch(view_cache_dependencies) 
    end

    def write_fragment(rendered_template)
      content = __vc_render_template(rendered_template)
      Rails.cache.fetch(view_cache_dependencies) do
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
