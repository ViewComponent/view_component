# frozen_string_literal: true

class DelegatedRenderChildComponent < ViewComponent::Base
  include ViewComponent::DelegatedRender

  delegate_render_to :@parent

  def initialize
    @parent = DelegatedRenderParentComponent.new
  end
end
