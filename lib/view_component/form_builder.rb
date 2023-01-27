# frozen_string_literal: true

module ViewComponent
  class FormBuilder < ActionView::Helpers::FormBuilder
    prepend ViewComponent::FormBuilderMixin
  end
end
