# frozen_string_literal: true

require "set"
require "i18n"
require "action_view/helpers/translation_helper"
require "active_support/concern"

module ViewComponent
  module Translatable
    extend ActiveSupport::Concern

    HTML_SAFE_TRANSLATION_KEY = /(?:_|\b)html\z/.freeze

    included do
      class_attribute :i18n_backend, instance_writer: false, instance_predicate: false
    end

    class_methods do
      def i18n_scope
        @i18n_scope ||= virtual_path.sub(%r{^/}, "").gsub(%r{/_?}, ".")
      end

      def _after_compile
        super

        return if CompileCache.compiled? self

        if (translation_files = _sidecar_files(%w[yml yaml])).any?
          self.i18n_backend = I18nBackend.new(
            i18n_scope: i18n_scope,
            load_paths: translation_files,
          )
        else
          # Cleanup if translations file has been removed since the last compilation
          self.i18n_backend = nil
        end
      end
    end

    class I18nBackend < ::I18n::Backend::Simple
      EMPTY_HASH = {}.freeze

      def initialize(i18n_scope:, load_paths:)
        @i18n_scope = i18n_scope.split(".")
        @load_paths = load_paths
      end

      # Ensure the Simple backend won't load paths from ::I18n.load_path
      def load_translations
        super(@load_paths)
      end

      def scope_data(data)
        @i18n_scope.reverse_each do |part|
          data = { part => data }
        end
        data
      end

      def store_translations(locale, data, options = EMPTY_HASH)
        super(locale, scope_data(data), options)
      end
    end

    def translate(key = nil, **options)
      return super unless i18n_backend
      return key.map { |k| translate(k, **options) } if key.is_a?(Array)

      locale = options.delete(:locale) || ::I18n.locale
      key = key&.to_s unless key.is_a?(String)
      key = "#{i18n_scope}#{key}" if key.start_with?(".")

      translated =
        catch(:exception) do
          i18n_backend.translate(locale, key, options)
        end

      # Fallback to the global translations
      if translated.is_a? ::I18n::MissingTranslation
        return super(key, locale: locale, **options)
      end

      if HTML_SAFE_TRANSLATION_KEY.match?(key)
        translated = translated.html_safe # rubocop:disable Rails/OutputSafety
      end

      translated
    end
    alias :t :translate

    # Exposes .i18n_scope as an instance method
    def i18n_scope
      self.class.i18n_scope
    end
  end
end
