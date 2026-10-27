# frozen_string_literal: true

# Declares its slots with class names, which resolve against the component
# rather than from the top level, so they can't be found statically.
class CacheableSlotClassNameComponent < ViewComponent::Base
  renders_one :header, "HTTPUntrackedComponent"
  renders_many :items, types: {child: "UntrackedChildComponent"}

  erb_template <<~ERB
    <div class="cacheable-slot-class-name"><%= header %><% items.each do |item| %><%= item %><% end %></div>
  ERB
end
