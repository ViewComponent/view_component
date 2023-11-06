class PreviewSourceComponentPreview < ViewComponent::Preview
  def default
    render(PreviewSourceComponent.new)
  end
end
