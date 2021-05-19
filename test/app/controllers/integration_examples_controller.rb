# frozen_string_literal: true

class IntegrationExamplesController < ActionController::Base
  layout false

  def member_var_in_controller
    @user_name = "I was set in the controller action"
  end

  def member_var_in_view
  end

  def variants
    request.variant = params[:variant].to_sym if params[:variant]
  end

  def button_to_component
  end

  def container_component
  end

  def controller_inline
    render(ControllerInlineComponent.new(message: "bar"))
  end

  def controller_inline_baseline
    render("integration_examples/_controller_inline", locals: { message: "bar" })
  end

  def controller_to_string
    # Ensures render_to_string_monkey_patch.rb correctly calls `super` when
    # not rendering a component:
    render_to_string("integration_examples/_controller_inline", locals: { message: "bar" })

    render(plain: render_to_string(ControllerInlineComponent.new(message: "bar")))
  end

  def controller_inline_render_component
    render_component(ControllerInlineComponent.new(message: "bar"))
  end

  def controller_to_string_render_component
    render(plain: render_component_to_string(ControllerInlineComponent.new(message: "bar")))
  end

  def products
    @products = [OpenStruct.new(name: "Radio clock"), OpenStruct.new(name: "Mints")]
  end

  def inline_products
    products = [OpenStruct.new(name: "Radio clock"), OpenStruct.new(name: "Mints")]

    render(ProductComponent.with_collection(products, notice: "Today only"))
  end
end
