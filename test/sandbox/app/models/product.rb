class Product < Struct.new(:name)
  def initialize(name:)
    super(name)
  end
end
