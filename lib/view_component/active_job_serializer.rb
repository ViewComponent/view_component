# frozen_string_literal: true

require "active_job/serializers"

module ViewComponent
  class ActiveJobSerializer < ActiveJob::Serializers::ObjectSerializer
    def klass
      ViewComponent::Serializable::Proxy
    end

    def serialize?(argument)
      argument.is_a?(ViewComponent::Serializable::Proxy)
    end

    def serialize(proxy)
      super(proxy.serialize)
    end

    def deserialize(hash)
      ViewComponent::Serializable::Proxy.deserialize(hash)
    end
  end
end
