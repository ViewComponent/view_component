class AroundRenderComponent < ViewComponent::Base
  def call
    "Hi!".html_safe
  end

  def around_render
    Instrumenter.tick do
      yield
    end
  end
end
