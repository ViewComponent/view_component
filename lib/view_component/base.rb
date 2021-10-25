# frozen_string_literal: true

require "action_view"
require "active_support/configurable"
require "view_component/core"
require "view_component/content_areas"
require "view_component/slotable"
require "view_component/slotable_v2"

module ViewComponent
  class Base < Core
    include ViewComponent::ContentAreas
    include ViewComponent::SlotableV2
    include ActiveSupport::Configurable

    class_attribute :content_areas
    self.content_areas = [] # class_attribute:default doesn't work until Rails 5.2

    # For CSRF authenticity tokens in forms
    delegate :form_authenticity_token, :protect_against_forgery?, :config, to: :helpers

    # The current controller. Use sparingly as doing so introduces coupling
    # that inhibits encapsulation & reuse, often making testing difficult.
    #
    # @return [ActionController::Base]
    def controller
      if view_context.nil?
        raise(
          ViewContextCalledBeforeRenderError,
          "`#controller` cannot be used during initialization, as it depends " \
          "on the view context that only exists once a ViewComponent is passed to " \
          "the Rails render pipeline.\n\n" \
          "It's sometimes possible to fix this issue by moving code dependent on " \
          "`#controller` to a `#before_render` method: https://viewcomponent.org/api.html#before_render--void."
        )
      end

      @__vc_controller ||= view_context.controller
    end

    # A proxy through which to access helpers. Use sparingly as doing so introduces
    # coupling that inhibits encapsulation & reuse, often making testing difficult.
    #
    # @return [ActionView::Base]
    def helpers
      if view_context.nil?
        raise(
          ViewContextCalledBeforeRenderError,
          "`#helpers` cannot be used during initialization, as it depends " \
          "on the view context that only exists once a ViewComponent is passed to " \
          "the Rails render pipeline.\n\n" \
          "It's sometimes possible to fix this issue by moving code dependent on " \
          "`#helpers` to a `#before_render` method: https://viewcomponent.org/api.html#before_render--void."
        )
      end

      # Attempt to re-use the original view_context passed to the first
      # component rendered in the rendering pipeline. This prevents the
      # instantiation of a new view_context via `controller.view_context` which
      # always returns a new instance of the view context class.
      #
      # This allows ivars to remain persisted when using the same helper via
      # `helpers` across multiple components and partials.
      @__vc_helpers ||= original_view_context || controller.view_context
    end

    # The current request. Use sparingly as doing so introduces coupling that
    # inhibits encapsulation & reuse, often making testing difficult.
    #
    # @return [ActionDispatch::Request]
    def request
      @request ||= controller.request if controller.respond_to?(:request)
    end

    private

    # Set the controller used for testing components:
    #
    #     config.view_component.test_controller = "MyTestController"
    #
    # Defaults to ApplicationController. Can also be configured on a per-test
    # basis using `with_controller_class`.
    #
    mattr_accessor :test_controller
    @@test_controller = "ApplicationController"

    # Set if render monkey patches should be included or not in Rails <6.1:
    #
    #     config.view_component.render_monkey_patch_enabled = false
    #
    mattr_accessor :render_monkey_patch_enabled, instance_writer: false, default: true

    # Enable or disable source code previews in component previews:
    #
    #     config.view_component.show_previews_source = true
    #
    # Defaults to `false`.
    #
    mattr_accessor :show_previews_source, instance_writer: false, default: false

    # Always generate a Stimulus controller alongside the component:
    #
    #     config.view_component.generate_stimulus_controller = true
    #
    # Defaults to `false`.
    #
    mattr_accessor :generate_stimulus_controller, instance_writer: false, default: false

    # Path for component files
    #
    #     config.view_component.view_component_path = "app/my_components"
    #
    # Defaults to "app/components".
    mattr_accessor :view_component_path, instance_writer: false, default: "app/components"

    # Parent class for generated components
    #
    #     config.view_component.component_parent_class = "MyBaseComponent"
    #
    # Defaults to "ApplicationComponent" if defined, "ViewComponent::Base" otherwise.
    mattr_accessor :component_parent_class,
                   instance_writer: false

    class << self
      # @private
      def inherited(child)
        # If Rails application is loaded, add application url_helpers to the component context
        # we need to check this to use this gem as a dependency
        if defined?(Rails) && Rails.application
          child.include Rails.application.routes.url_helpers unless child < Rails.application.routes.url_helpers
        end

        super
      end
    end

    ActiveSupport.run_load_hooks(:view_component, self)
  end
end
