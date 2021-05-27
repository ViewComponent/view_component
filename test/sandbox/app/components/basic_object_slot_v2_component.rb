# frozen_string_literal: true

class BasicObjectSlotV2Component < ViewComponent::Base
  renders_one :link, "Link"

  class Link < ViewComponent::Base
    attr_reader :method

    def initialize(method:)
      @method = method
    end
  end

  def call
    helpers.tag.a(data: { method: link.method })
  end
end
