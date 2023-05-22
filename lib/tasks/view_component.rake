require "view_component/codemods/v3_slot_setters"

namespace :view_component do
  task detect_legacy_slots: :environment do
    custom_paths = parse_custom_paths(ARGV)
    ViewComponent::Codemods::V3SlotSetters.new(view_path: custom_paths).call
  end

  task migrate_legacy_slots: :environment do
    custom_paths = parse_custom_paths(ARGV)
    ViewComponent::Codemods::V3SlotSetters.new(view_path: custom_paths, migrate: true).call
  end

  def parse_custom_paths(args)
    args.each { |a| task a.to_sym {} }
    args.compact.map { |path| Rails.root.join(path) }
  end
end
