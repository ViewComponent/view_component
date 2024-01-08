class InlineSlotHtmlEscapeComponent < ViewComponent::Base
  renders_one :empty_state

  def initialize(heading:, paragraph:, url:)
    @heading = heading
    @paragraph = paragraph
    @url = url
  end

  def call
    return empty_state unless @heading.nil?

    link_to @url do
      @heading +
        tag.p(@paragraph)
    end
  end
end
