# frozen_string_literal: true

module ViewComponent::Cacheable
  extend ActiveSupport::Concern

  included do
    class_attribute :__vc_cache_dependencies, default: [:format, :__vc_format, :identifier]

    # For caching, such as #cache_if
    #
    # @private
    def view_cache_dependencies
      return if __vc_cache_dependencies.blank? || __vc_cache_dependencies.none? || __vc_cache_dependencies.nil?

      computed_view_cache_dependencies = __vc_cache_dependencies.map { |dep| if respond_to?(dep) then public_send(dep) end }
      ActiveSupport::Cache.expand_cache_key(computed_view_cache_dependencies)
    end

    # Render component from cache if possible
    #
    # @private
    def __vc_render_cacheable(rendered_template)
      if __vc_cache_dependencies != [:format, :__vc_format]
        Rails.cache.fetch(view_cache_dependencies) do
          __vc_render_template(rendered_template)
        end
      else
        __vc_render_template(rendered_template)
      end
    end
  end

  class_methods do
    # For caching the component
    def cache_on(*args)
      __vc_cache_dependencies.push(*args)
    end

    def inherited(child)
      child.__vc_cache_dependencies = __vc_cache_dependencies.dup

      super
    end
  end
end
