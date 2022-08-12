describe PreviewComponent do
  before do
    ViewComponent::Preview.load_previews
  end

  it "renders the preview" do
    render_preview(:default)

    expect(page).to have_css "h1", text: "Lorem Ipsum"
  end

  it "multiple renders the preview" do
    render_preview(:multiple)

    expect(page).to have_css ".preview-component", count: 2
    expect(page).to have_css "h1", text: "Lorem Ipsum"
    expect(page).to have_css "h1", text: "Super search"
  end
end

describe "PreviewComponent" do
  before do
    ViewComponent::Preview.load_previews
  end

  it "raises an error" do
    expect { render_preview(:default) }.to raise_error(/expected a described_class/)
  end
end
