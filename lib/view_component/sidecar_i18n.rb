# frozen_string_literal: true

require "set"
require "i18n"
require "action_view/helpers/translation_helper"

module ViewComponent
  module SidecarI18n
    def self.included(base)
      base.class_attribute :i18n_backend, instance_writer: false, instance_predicate: false
      base.extend ClassMethods
    end

    class I18nBackend < ::I18n::Backend::Simple
      def initialize(load_paths)
        @load_paths = load_paths
      end

      # Ensure the Simple backend won't load paths from ::I18n.load_path
      def load_translations
        super(@load_paths)
      end
    end

    def translate(key = nil, locale: nil, **options)
      locale ||= ::I18n.locale

      result = catch(:exception) do
        if key.is_a?(Array)
          key.map { |k| i18n_backend.translate(locale, k, options) }
        else
          i18n_backend.translate(locale, key, options)
        end
      end

      # Fallback to the global translations
      result = helpers.t(key, locale: locale, **options) if result.is_a? ::I18n::MissingTranslation

      result
    end
    alias :t :translate

    module ClassMethods
      def _after_compile
        super

        unless CompileCache.compiled? self
          self.i18n_backend = I18nBackend.new(_sidecar_files(%w[yml yaml]))
        end
      end
    end
  end
end
