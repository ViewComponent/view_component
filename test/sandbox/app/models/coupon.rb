class Coupon < Struct.new(:percent_off)
  def initialize(percent_off:)
    super(percent_off)
  end
end
