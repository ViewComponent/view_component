# frozen_string_literal: true

require "test_helper"
require "view_component/codemods/v3_slot_setters"

class V3SlotSettersTest < Minitest::Test
  def teardown
    restore_legacy_slots
  end

  def test_detects_legacy_slots
    output = capture_output do
      ViewComponent::Codemods::V3SlotSetters.new.call
    end

    assert_match "_v2_slots_setters_exact.html.erb\n=> line 2: probably replace `component.title` with `component.with_title`", output
    assert_match "line 8: probably replace `component.tab` with `component.with_tab`", output
    assert_match "line 11: probably replace `component.tab` with `component.with_tab`", output
    assert_match "_v2_slots_setters_alias.html.erb\n=> line 2: maybe replace `subtitle` with `with_subtitle`", output
  end

  def test_migrate_legacy_slots
    ViewComponent::Codemods::V3SlotSetters.new(migrate: true).call

    output = capture_output do
      ViewComponent::Codemods::V3SlotSetters.new.call
    end

    refute_match "_v2_slots_setters_exact.html.erb\n=> line 2: probably replace `component.title` with `component.with_title`", output
    refute_match "line 6: probably replace `component.tab` with `component.with_tab`", output
    refute_match "line 9: probably replace `component.tab` with `component.with_tab`", output
    refute_match "_v2_slots_setters_alias.html.erb\n=> line 2: maybe replace `subtitle` with `with_subtitle`", output
  end

  private

  def capture_output
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end

  def restore_legacy_slots
    test_views = [
      Rails.root.join("app/views/codemods/_v2_slots_setters_alias.html.erb"),
      Rails.root.join("app/views/codemods/_v2_slots_setters_exact.html.erb")
    ]
    test_views.each do |file|
      content = File.read(file)
      content.gsub!("with_", "")
      File.write(file, content)
    end
  end
end
