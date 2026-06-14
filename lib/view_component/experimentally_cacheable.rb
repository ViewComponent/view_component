# frozen_string_literal: true

require "view_component/cache_registry"
require "view_component/cache_digestor"

module ViewComponent::ExperimentallyCacheable
  extend ActiveSupport::Concern

  included do
    class_attribute :__vc_cache_key_block, default: nil
    class_attribute :__vc_cache_if, default: nil

    # For caching, such as #cache_if
    #
    # @private
    def view_cache_dependencies
      return [] unless self.class.__vc_cache_key_block

      @__vc_cache_dependencies ||= Array(instance_exec(&self.class.__vc_cache_key_block))
    end

    def view_cache_options
      return @__vc_cache_options if instance_variable_defined?(:@__vc_cache_options)

      return @__vc_cache_options = nil unless self.class.__vc_cache_key_block

      template_key = __vc_cache_template_key
      return @__vc_cache_options = nil unless template_key

      @__vc_cache_options = cache_fragment_name(
        [:view_component, view_cache_dependencies],
        digest_path: __vc_component_digest_path(template_key)
      )
    end

    # Render component from cache if possible
    #
    # @private
    def __vc_render_template(safe_call)
      if __vc_cache_enabled? && __vc_controller_perform_caching? && (cache_key = view_cache_options)
        ViewComponent::CachingRegistry.track_caching do
          template_fragment(cache_key, safe_call)
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

    def template_fragment(cache_key, safe_call)
      if (content = read_fragment(cache_key))
        record_fragment_cache(:hit)
        content
      else
        record_fragment_cache(:miss)
        write_fragment(cache_key, safe_call)
      end
    end

    def record_fragment_cache(status)
      return unless Rails.application.config.view_component.instrumentation_enabled.present?
      return unless defined?(@view_renderer)

      @view_renderer.cache_hits[@current_template&.virtual_path] = status
    end

    def read_fragment(cache_key)
      controller.read_fragment(cache_key)
    end

    def write_fragment(cache_key, safe_call)
      content = instance_exec(&safe_call)
      controller.write_fragment(cache_key, content)
      content
    end

    def component_digest
      return @__vc_component_digest ||= __vc_compute_component_digest unless ActionView::Base.cache_template_loading

      self.class.__vc_component_digest
    end

    def __vc_compute_component_digest
      ViewComponent::CacheDigestor.digest(self)
    end

    def __vc_component_digest_path(template_key)
      digest = component_digest
      call_method_name, template_virtual_path = template_key
      [self.class.virtual_path, call_method_name, template_virtual_path, digest].compact.join(":")
    end

    def __vc_controller_perform_caching?
      controller.respond_to?(:perform_caching) && controller.perform_caching
    end

    def __vc_cache_enabled?
      cache_if = self.class.__vc_cache_if
      return true if cache_if.nil?

      case cache_if
      when Symbol, String
        public_send(cache_if)
      when Proc
        instance_exec(&cache_if)
      else
        !!cache_if
      end
    end
  end

  class_methods do
    def after_compile
      super

      __vc_precompute_component_digest if ActionView::Base.cache_template_loading
    end

    def __vc_component_digest
      @__vc_component_digest ||= ViewComponent::CacheDigestor.digest(self)
    end

    def __vc_precompute_component_digest
      @__vc_component_digest = ViewComponent::CacheDigestor.digest(self)
    end

    def cache(&block)
      self.__vc_cache_key_block = block
    end

    def cache_if(value = nil, &block)
      self.__vc_cache_if = block || value
    end

    def inherited(child)
      child.__vc_cache_key_block = __vc_cache_key_block
      child.__vc_cache_if = __vc_cache_if

      super
    end
  end
end
