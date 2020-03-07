# frozen_string_literal: true

module ViewComponent
  module Rendering
    extend ActiveSupport::Concern
    include ViewComponent::ViewPaths
  end
end
