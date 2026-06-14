class PartialModel < Struct.new(:to_partial_path)
  def initialize(to_partial_path:)
    super(to_partial_path)
  end
end
