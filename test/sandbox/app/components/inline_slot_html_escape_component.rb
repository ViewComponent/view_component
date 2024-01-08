class InlineSlotHtmlEscapeComponent < ViewComponent::Base
  renders_one :empty_state

  def initialize(counter:, heading:, url:)
    @counter = counter
    @heading = heading
    @url = url
  end

  def call
    return empty_state unless @heading.nil?

    link_to @url do
      @counter +
        tag.p(@heading)
    end
  end
end
