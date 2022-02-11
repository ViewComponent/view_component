# frozen_string_literal: true

class OtherFormBuilder < ActionView::Helpers::FormBuilder
  def text_field(*)
    "changed by default form builder"
  end
end

class DefaultFormBuilderController < ActionController::Base
  default_form_builder OtherFormBuilder
end
