class PreviewComponent < ActionView::Component::Base
  validates :title, presence: true

  def initialize(cta: nil, title:)
    @cta = cta
    @title = title
  end

  private

  attr_reader :cta, :title
end
