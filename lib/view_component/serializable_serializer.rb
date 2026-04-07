# frozen_string_literal: true

require "active_job"
require "view_component/serializable"

module ViewComponent
  class SerializableSerializer < ActiveJob::Serializers::ObjectSerializer
    def klass
      ViewComponent::Base
    end

    def serialize?(argument)
      argument.is_a?(ViewComponent::Base) &&
        argument.respond_to?(:serializable_kwargs)
    end

    def serialize(component)
      unless component.serializable_kwargs
        raise ArgumentError,
          "#{component.class.name} was instantiated with .new instead of .serializable. " \
          "Use #{component.class.name}.serializable(...) to create a serializable instance."
      end

      super(
        "component" => component.class.name,
        "kwargs" => ActiveJob::Arguments.serialize([component.serializable_kwargs])
      )
    end

    def deserialize(hash)
      klass = hash["component"].safe_constantize
      raise ArgumentError, "Cannot deserialize unknown component: #{hash["component"]}" unless klass

      kwargs = ActiveJob::Arguments.deserialize(hash["kwargs"]).first
      klass.serializable(**kwargs.symbolize_keys)
    end
  end
end
