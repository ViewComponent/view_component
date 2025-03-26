# frozen_string_literal: true

module ViewComponent::Cacheable
  extend ActiveSupport::Concern

  included do
    class_attribute :__vc_cache_dependencies, default: []

    # For caching, such as #cache_if
    #
    # @private
    def view_cache_dependencies
      return if __vc_cache_dependencies.blank? || __vc_cache_dependencies.none?

      __vc_cache_dependencies.filter_map { |dep| send(dep) }
    end

    # Render component from cache if possible
    #
    # @private
    def __vc_render_cacheable(rendered_template)
      if view_cache_dependencies.present?
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
      child.__vc_cache_dependencies + __vc_cache_dependencies.dup if __vc_cache_dependencies.present?

      super
    end
  end
end
