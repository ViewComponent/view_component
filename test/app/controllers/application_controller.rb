# frozen_string_literal: true

class ApplicationController < ActionController::Base
  def variants
    request.variant = :tablet if params[:tablet]
    request.variant = :phone if params[:phone]
  end
end
