# frozen_string_literal: true

class CollectionParameterWithActiveModelComponent < ViewComponent::Base
  if Rails.version.to_f >= 5.2
    include ActiveModel::Attributes

    attribute :name, :string
  else
    attr_accessor :name

    def initialize(name: nil)
      @name = name
    end
  end

  with_collection_parameter :name

  def call; end
end
