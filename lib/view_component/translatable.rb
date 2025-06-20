# frozen_string_literal: true

require "erb"
require "i18n"
require "active_support/concern"

module ViewComponent
  module Translatable
    extend ActiveSupport::Concern

    HTML_SAFE_TRANSLATION_KEY = /(?:_|\b)html\z/
    private_constant :HTML_SAFE_TRANSLATION_KEY

    TRANSLATION_EXTENSIONS = %w[yml yaml].freeze
    private_constant :TRANSLATION_EXTENSIONS

    included do
      class_attribute :__vc_i18n_backend, instance_writer: false, instance_predicate: false
    end

    class_methods do
      def __vc_i18n_scope
        @__vc_i18n_scope ||= virtual_path.sub(%r{^/}, "").gsub(%r{/_?}, ".")
      end

      def __vc_build_i18n_backend
        return if __vc_compiled?

        # We need to load the translations files from the ancestors so a component
        # can inherit translations from its parent and is able to overwrite them.
        translation_files = ancestors.reverse_each.with_object([]) do |ancestor, files|
          if ancestor.is_a?(Class) && ancestor < ViewComponent::Base
            files.concat(ancestor.sidecar_files(TRANSLATION_EXTENSIONS))
          end
        end

        # In development it will become nil if the translations file is removed
        self.__vc_i18n_backend = if translation_files.any?
          I18nBackend.new(
            scope: __vc_i18n_scope,
            load_paths: translation_files
          )
        end
      end

      def __vc_i18n_key(key, scope = nil)
        scope = scope.join(".") if scope.is_a? Array
        key = key&.to_s unless key.is_a?(String)
        key = "#{scope}.#{key}" if scope
        key = "#{__vc_i18n_scope}#{key}" if key.start_with?(".")
        key
      end

      def translate(key = nil, **options)
        return key.map { |k| translate(k, **options) } if key.is_a?(Array)

        __vc_ensure_compiled

        locale = options.delete(:locale) || ::I18n.locale
        key = __vc_i18n_key(key, options.delete(:scope))

        __vc_i18n_backend.translate(locale, key, options)
      end

      alias_method :t, :translate
    end

    class I18nBackend < ::I18n::Backend::Simple
      EMPTY_HASH = {}.freeze

      def initialize(scope:, load_paths:)
        @__vc_i18n_scope = scope.split(".").map(&:to_sym)
        @__vc_load_paths = load_paths
      end

      # Ensure the Simple backend won't load paths from ::I18n.load_path
      def load_translations
        super(@__vc_load_paths)
      end

      def scope_data(data)
        @__vc_i18n_scope.reverse_each do |part|
          data = {part => data}
        end
        data
      end

      def store_translations(locale, data, options = EMPTY_HASH)
        super(locale, scope_data(data), options)
      end
    end

    def translate(key = nil, **options)
      raise ViewComponent::TranslateCalledBeforeRenderError if view_context.nil?

      return @view_context.translate(key, **options) unless __vc_i18n_backend
      return key.map { |k| translate(k, **options) } if key.is_a?(Array)

      locale = options.delete(:locale) || ::I18n.locale
      key = self.class.__vc_i18n_key(key, options.delete(:scope))
      as_html = HTML_SAFE_TRANSLATION_KEY.match?(key)

      __vc_html_escape_translation_options!(options) if as_html

      if key.start_with?(__vc_i18n_scope + ".")
        translated =
          catch(:exception) do
            __vc_i18n_backend.translate(locale, key, options)
          end

        # Fallback to the global translations
        if translated.is_a? ::I18n::MissingTranslation
          return @view_context.translate(key, locale: locale, **options)
        end

        translated = __vc_html_safe_translation(translated) if as_html
        translated
      else
        @view_context.translate(key, locale: locale, **options)
      end
    end
    alias_method :t, :translate

    def __vc_i18n_scope
      self.class.__vc_i18n_scope
    end

    private

    def __vc_html_safe_translation(translation)
      if translation.respond_to?(:map)
        translation.map { |element| __vc_html_safe_translation(element) }
      else
        # It's assumed here that objects loaded by the i18n backend will respond to `#html_safe?`.
        # It's reasonable that if we're in Rails, `active_support/core_ext/string/output_safety.rb`
        # will provide this to `Object`.
        translation.html_safe
      end
    end

    def __vc_html_escape_translation_options!(options)
      options.except(*::I18n::RESERVED_KEYS).each do |name, value|
        next if name == :count && value.is_a?(Numeric)

        options[name] = ERB::Util.html_escape(value.to_s)
      end
    end
  end
end
