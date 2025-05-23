class AccordionComponent < ViewComponent::Base
  renders_many :items, Accordion::ItemComponent
end