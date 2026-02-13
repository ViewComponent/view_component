# frozen_string_literal: true

require "view_component/cache_registry"
require "view_component/cache_digestor"

module ViewComponent::ExperimentallyCacheable
  extend ActiveSupport::Concern

  included do
    class_attribute :__vc_cache_dependencies, default: Set.new
    class_attribute :__vc_cache_if, default: nil

    # For caching, such as #cache_if
    #
    # @private
    def view_cache_dependencies
      @__vc_cache_dependencies ||= self.class.__vc_cache_dependencies.map { |dep| send(dep) }
    end

    def view_cache_options
      return @__vc_cache_options if instance_variable_defined?(:@__vc_cache_options)

      dependencies = self.class.__vc_cache_dependencies
      return @__vc_cache_options = nil if dependencies.empty?

      template_key = __vc_cache_template_key
      return @__vc_cache_options = nil unless template_key

      expanded_key = ActiveSupport::Cache.expand_cache_key([__vc_static_cache_key_parts(template_key), view_cache_dependencies])
      @__vc_cache_options = combined_fragment_cache_key(expanded_key)
    end

    # Render component from cache if possible
    #
    # @private
    def __vc_render_cacheable(safe_call)
      if __vc_cache_enabled? && (cache_key = view_cache_options)
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
        @view_renderer.cache_hits[@current_template&.virtual_path] = :hit if defined?(@view_renderer)
        content
      else
        @view_renderer.cache_hits[@current_template&.virtual_path] = :miss if defined?(@view_renderer)
        write_fragment(cache_key, safe_call)
      end
    end

    def read_fragment(cache_key)
      Rails.cache.read(cache_key)
    end

    def write_fragment(cache_key, safe_call)
      content = instance_exec(&safe_call)
      Rails.cache.write(cache_key, content)
      content
    end

    def combined_fragment_cache_key(key)
      cache_key = [:view_component, ENV["RAILS_CACHE_ID"] || ENV["RAILS_APP_VERSION"], key]
      cache_key.flatten!(1)
      cache_key.compact!
      cache_key
    end

    def component_digest
      return @__vc_component_digest ||= __vc_compute_component_digest unless ActionView::Base.cache_template_loading

      klass = self.class
      digest = klass.instance_variable_get(:@__vc_component_digest)
      return digest if digest

      klass.instance_variable_set(:@__vc_component_digest, __vc_compute_component_digest)
    end

    def __vc_compute_component_digest
      ViewComponent::CacheDigestor.new(component: self).digest
    end

    def __vc_static_cache_key_parts(template_key)
      klass = self.class
      digest = component_digest
      call_method_name, template_virtual_path = template_key
      cache_key = [call_method_name, template_virtual_path, digest]

      static_key_cache = klass.instance_variable_get(:@__vc_static_cache_key_parts) ||
        klass.instance_variable_set(:@__vc_static_cache_key_parts, {})

      static_key_cache[cache_key] ||= [klass.name, klass.virtual_path, [call_method_name, template_virtual_path].freeze, digest].freeze
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
    def cache_if(value = nil, &block)
      self.__vc_cache_if = block || value
    end

    # For caching the component
    def cache_on(*args)
      __vc_cache_dependencies.merge(args)
    end

    def inherited(child)
      child.__vc_cache_dependencies = __vc_cache_dependencies.dup
      child.__vc_cache_if = __vc_cache_if

      super
    end
  end
end
