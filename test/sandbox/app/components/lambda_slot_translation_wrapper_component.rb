# frozen_string_literal: true

class LambdaSlotTranslationWrapperComponent < ViewComponent::Base
  def call
    render "shared/lambda_slot_translation"
  end
end
