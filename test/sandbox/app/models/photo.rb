class Photo < Struct.new(:title, :caption, :url)
  def initialize(title:, caption:, url:)
    super(title, caption, url)
  end
end
