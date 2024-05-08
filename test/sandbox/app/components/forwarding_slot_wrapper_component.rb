# frozen_string_literal: true

class ForwardingSlotWrapperComponent < ViewComponent::Base
end

unless defined?(ForwardingSlotComponent)
  class ForwardingSlotComponent < ViewComponent::Base
    def initialize
      @target = TargetSlotComponent.new
    end

    def with_target_content(&block)
      @target.with_target_content(&block)
    end

    def before_render
      content
    end

    def call
      render(@target)
    end
  end

  class TargetSlotComponent < ViewComponent::Base
    renders_one :target_content, "TargetContentComponent"

    def call
      target_content
    end
  end

  class TargetContentComponent < ViewComponent::Base
    def call
      content
    end
  end
end
