# frozen_string_literal: true

class DefaultFormBuilderController < ActionController::Base
  class OtherFormBuilder < ActionView::Helpers::FormBuilder
    def text_field(*)
      "changed by default form builder"
    end
  end

  default_form_builder OtherFormBuilder
end
