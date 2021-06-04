module Shared
  class ExampleComponent < ViewComponent::Base
    def initialize(title:)
      @title = title
    end
  end
end