# frozen_string_literal: true

module ViewComponent
  # Compiles the HTML+ERB templates of components through Herb, the way
  # `ActionView::HerbChecker` does for the templates in the view paths.
  #
  # Sidecar templates aren't in the view paths and inline templates aren't
  # files, so `bin/rails herb:check` doesn't reach them on its own.
  #
  # @private
  class HerbChecker
    Failure = Data.define(:component, :template, :error) do
      # @return [String]
      def identifier
        "#{template.handler_template.short_identifier} (#{component.name || component.inspect})"
      end
    end

    # Whether this version of Action View compiles ERB through Herb.
    #
    # @return [Boolean]
    def self.supported?
      ActionView::Template::Handlers::ERB.const_defined?(:Herb, false)
    end

    # @param components [Array<Class>] components whose templates to check
    #
    # @return [Array<Failure>]
    def self.check(components = ViewComponent::Base.descendants.reject(&:anonymous?))
      # Required here rather than at load time, so `supported?` doesn't need
      # the herb gem.
      require "action_view/template/handlers/erb/herb"
      require "herb/engine/validators/security_validator"

      handler = ActionView::Template::Handlers::ERB.new

      components.flat_map do |component|
        component.__vc_compiler.source_templates.filter_map do |template|
          next unless template.html? && template.details.handler == :erb

          visitors = [::Herb::Engine::Validators::SecurityValidator.new]

          begin
            handler.call(
              template.handler_template,
              template.handler_source,
              implementation: ActionView::Template::Handlers::ERB::Herb,
              validate_ruby: true,
              visitors: visitors
            )
            nil
          rescue ::Herb::Engine::CompilationError, ::Herb::Engine::SecurityError => error
            Failure.new(component, template, error)
          end
        end
      end
    end
  end
end
