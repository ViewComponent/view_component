class AroundRenderComponent < ViewComponent::Base
  def call
    "Hi!"
  end

  def around_render
    Instrumenter.tick do
      yield
    end
  end
end
