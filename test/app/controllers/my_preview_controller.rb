# frozen_string_literal: true

class MyPreviewController < ViewComponentsController

  def index
    if params[:custom_controller].present?
      render plain: "Custom controller"
    else
      super
    end
  end
end
