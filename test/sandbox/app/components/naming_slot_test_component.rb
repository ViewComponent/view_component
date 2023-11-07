class NamingSlotTestComponent < ViewComponent::Base
  renders_many :series, "Serie"

  class Serie < ViewComponent::Base
    def initialize(name:)
      @name = name
    end
  end
end