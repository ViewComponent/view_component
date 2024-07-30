class SlotableDefaultInstanceComponent < ViewComponent::Base
  include ViewComponent::SlotableDefault

  erb_template <<~ERB
    <h1><%= header %></h1>
  ERB

  renders_one :header

  def default_header
    MyComponent.new
  end
end
