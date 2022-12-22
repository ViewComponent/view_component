# frozen_string_literal: true

class InitializerTranslationsComponent < ViewComponent::Base
  def initialize
    @title = t('.title')
    @subtitle = t('translations_component.subtitle')
  end

  def call
    @title + @subtitle
  end
end
