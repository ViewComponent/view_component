class SlotableDefaultComponent < ViewComponent::Base
  erb_template <<~ERB
    <h1><%= header %></h1>
  ERB

  renders_one :header

  def default_header
    "hello,world!"
  end
end
