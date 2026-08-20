# frozen_string_literal: true

require "view_component/cache_digest"

module ViewComponent
  # Experimental caching support for ViewComponents.
  #
  # **This API is experimental.** It may change or be removed in a non-major
  # release. Please share feedback in
  # https://github.com/ViewComponent/view_component/issues/234.
  #
  # Including this module does two things:
  #
  # 1. Registers the component with Rails' template digest tree, so a
  #    `<% cache %>` block wrapping the component in a view is invalidated when
  #    the component's template, Ruby class, sidecar files, or child components
  #    change.
  # 2. Enables the `cache_on` macro, which caches the component's own rendered
  #    output.
  #
  # ```ruby
  # class MessageComponent < ViewComponent::Base
  #   include ViewComponent::ExperimentallyCacheable
  #
  #   cache_on :message
  #
  #   def initialize(message:)
  #     @message = message
  #   end
  # end
  # ```
  module ExperimentallyCacheable
    extend ActiveSupport::Concern

    included do
      ViewComponent::CacheDigest.install!
      ViewComponent::CacheDigest.register(self)
    end

    class_methods do
      # Declare the values that identify a rendering of this component.
      #
      # Each argument names a method on the component whose value is mixed into
      # the cache key, alongside a digest of the component's source. Private
      # methods are allowed.
      #
      # ```ruby
      # cache_on :message, :current_user
      # ```
      #
      # Calling `cache_on` opts the component into caching its own output.
      # Without it, including this module only registers the component with
      # Rails' digest tree.
      #
      # These methods are called before the component renders, so they can only
      # depend on the component's own state, not on `helpers` or the view
      # context.
      #
      # @param methods [Array<Symbol>] Methods whose values form the cache key.
      # @return [void]
      def cache_on(*methods)
        @__vc_cache_on = __vc_cache_on | methods.map(&:to_sym)
      end

      # @private
      def __vc_cache_on
        @__vc_cache_on ||= superclass.respond_to?(:__vc_cache_on) ? superclass.__vc_cache_on : []
      end

      # @private
      def __vc_cacheable?
        true
      end

      # Whether this component caches its own rendered output.
      #
      # @return [Boolean]
      def __vc_caches_output?
        __vc_cache_on.any?
      end

      # A digest of everything this component renders from: its template, its
      # Ruby class, its sidecar files, its superclasses, and the components and
      # partials it renders.
      #
      # Computed with Rails' own `ActionView::Digestor`, so it's the same digest
      # used to invalidate `<% cache %>` blocks.
      #
      # Usable outside a request, where no view context exists:
      #
      # ```ruby
      # MessageComponent.cache_digest
      # ```
      #
      # @param finder [ActionView::LookupContext] Defaults to a lookup context
      #   built from `ActionController::Base.view_paths`.
      # @param format [Symbol]
      # @return [String]
      def cache_digest(finder: nil, format: :html)
        ViewComponent::CacheDigest.digest(
          self,
          finder: finder || ViewComponent::CacheDigest.default_finder,
          format: format
        )
      end

      # @private
      def inherited(child)
        super
        ViewComponent::CacheDigest.register(child)
      end
    end

    # Renders the component, reading from and writing to the Rails cache when
    # `cache_on` has been declared.
    #
    # @private
    def render_in(view_context, **, &block)
      return super unless self.class.__vc_caches_output?

      # Content provided by the caller isn't part of the cache key, so caching
      # it would serve one caller's content to another. Raised whether or not
      # caching is currently enabled, so the conflict surfaces in development
      # and test rather than only in production.
      if block || __vc_content_set_by_with_content_defined? || __vc_slots_set_by_caller?
        raise ContentPassedToCachedComponentError.new(self.class.name)
      end

      return super unless __vc_cache_enabled?(view_context)

      store = Rails.cache
      key = cache_key(view_context)

      if (cached = store.read(key))
        # Safe to mark as HTML-safe: the cached string was produced by this same
        # rendering pipeline, which escapes output before it's written.
        return cached.html_safe # rubocop:disable Rails/OutputSafety
      end

      super.tap do |output|
        store.write(key, output.to_s)
      end
    end

    # The cache key for this rendering of the component.
    #
    # Combines the component's identity, its source digest, the requested
    # format and variant, the current locale, and the values declared with
    # `cache_on`. Override for full control.
    #
    # @param view_context [ActionView::Base]
    # @return [String]
    def cache_key(view_context = nil)
      lookup_context = view_context&.lookup_context

      ActiveSupport::Cache.expand_cache_key(
        [
          "view_component",
          self.class.virtual_path,
          self.class.cache_digest(finder: lookup_context, format: __vc_cache_format(lookup_context)),
          __vc_cache_variant(lookup_context),
          I18n.locale,
          *__vc_cache_on_values
        ].compact
      )
    end

    private

    # Slots set by the caller via `with_*`. Checked before rendering, so slots
    # a component fills in for itself with a `default_*` method — which resolve
    # lazily during the render — aren't counted.
    def __vc_slots_set_by_caller?
      defined?(@__vc_set_slots) && @__vc_set_slots.present?
    end

    def __vc_cache_enabled?(view_context)
      return false unless defined?(Rails) && Rails.respond_to?(:cache) && Rails.cache

      controller = view_context.try(:controller)
      controller.respond_to?(:perform_caching) && controller.perform_caching
    end

    def __vc_cache_on_values
      self.class.__vc_cache_on.map do |method_name|
        unless respond_to?(method_name, true)
          raise UndefinedCacheKeyMethodError.new(self.class.name, method_name)
        end

        send(method_name)
      end
    end

    def __vc_cache_format(lookup_context)
      Array(lookup_context&.formats).first || :html
    end

    def __vc_cache_variant(lookup_context)
      Array(lookup_context&.variants).first
    end
  end
end
