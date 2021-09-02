# frozen_string_literal: true

class CollectionIterationExtendOverrideComponent < CollectionIterationComponent
  with_collection_parameter :override

  def initialize(override:, override_iteration:)
    @override = override
    @iteration = override_iteration
    @counter = @iteration.index + 1
  end
end
