require "view_component/codemods/v3_slot_setters"

namespace :view_component do
  task detect_legacy_slots: :environment do
    ARGV.each { |a| task a.to_sym {} }
    custom_paths = ARGV.compact.map { |path| Rails.root.join(path) }
    ViewComponent::Codemods::V3SlotSetters.new(view_path: custom_paths).call
  end

  task migrate_legacy_slots: :environment do
    ARGV.each { |a| task a.to_sym {} }
    custom_paths = ARGV.compact.map { |path| Rails.root.join(path) }
    ViewComponent::Codemods::V3SlotSetters.new(view_path: custom_paths, migrate: true).call
  end
end
