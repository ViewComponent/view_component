# frozen_string_literal: true

require "yaml"
require "pathname"

module ViewComponent
  module I18n
    # Expects a component to have a file with the same basename and
    # the .yml extension, holding translations scoped to the component's path.
    #
    # A component YML should look like this:
    #
    #   en:
    #     hello: "Hello World!"
    #
    # And inside the component will be possible to call
    #
    #   t(".hello") # => "Hello World!"
    #
    # Internally the scope will be expanded using the template's path.
    # As an example, the translation above from within
    # `app/components/example/greeting_component.html.erb` will result in
    # an internal I18n key like this:
    #
    #   en:
    #     example:
    #       greeting_component:
    #         hello: "Hello World!"
    #
    #
    def self.load(components_root: "#{Rails.root}/app/components", glob: "**/*component.{yml,yaml}")
      Dir["#{components_root}/#{glob}"].each.with_object({}) do |path, translations|
        relative_path = Pathname(path).relative_path_from(Pathname(components_root)).to_s
        component_translations = YAML.load_file(path, fallback: {})
        scopes = relative_path.sub(/\.ya?ml/, "").split("/")

        component_translations.to_h.each do |locale, scoped_translations|
          translations[locale] ||= {}
          scopes.reduce(translations[locale]) do |nested_translations, scope|
            nested_translations[scope] ||= {}
          end
          translations[locale].dig(*scopes).merge! scoped_translations
        end
      end
    end

    @i18n_initialized = false

    # Install the sidecar translations reloader
    def self.initialize_i18n(app = Rails.application, components_root: "#{Rails.root}/app/components")
      return if @i18n_initialized

      @i18n_initialized = true

      reloader = app.config.file_watcher.new [], components_root => [".yml", ".yaml"] do
        ::I18n.reload!
      end

      app.reloaders << reloader
      app.reloader.to_run do
        reloader.execute_if_updated { require_unload_lock! }
      end

      reloader.execute
    end
  end
end
