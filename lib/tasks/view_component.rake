require "view_component/codemods/v3_slot_setters"

namespace :view_component do
  task detect_legacy_slots: :environment do
    ViewComponent::Codemods::V3SlotSetters.new.call
  end
end
