# frozen_string_literal: true

class CardComponent < ViewComponent::Base
  with_content_areas :header, :body, :footer

  private

  def header_class_names
    header_attributes.fetch(:classes, "card-header")
  end

  def header_data_attributes
    header_attributes.fetch(:data, {})
  end

  def body_class_names
    body_attributes.fetch(:classes, "card-body")
  end

  def footer_class_names
    footer_attributes.fetch(:classes, "card-footer")
  end
end
