class TestErbComponent < ActionView::Component
  validates :content, presence: true

  def initialize(message:)
    @message = message
  end
end
