# frozen_string_literal: true

class ApplicationController < ActionController::Base
  layout false

  def variants
    request.variant = params[:variant].to_sym if params[:variant]
  end
end
