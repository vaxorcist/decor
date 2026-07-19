# decor/test/services/unvalidated_order_numbers_export_service_test.rb
# version 1.1
# v1.1 (Session 71 — test repair): Session 70's Owner Part Number feature
#   widened Component's uniqueness scope to (owner_id, component_type_id,
#   owner_part_number, serial_number), and blank serial_number now defaults
#   to "-" via before_validation instead of being left blank. Three
#   Component.create! calls here used owner three + memory_board with no
#   explicit serial_number, colliding with the charlie_vt100_terminal
#   fixture (owner three, memory_board, already "-"/"-") and, in one case,
#   with each other. Fixed by adding explicit distinct serial_number values.
# NEW (Session 65): Tests for UnvalidatedOrderNumbersExportService.
#
# All test components are created fresh in-test and assigned to owners(:three)
# (the neutral owner), for the same reason as the revalidation service test —
# no hardcoded counts against alice's/bob's fixture data.
#
# Existing components.yml fixtures all have a blank order_number, so they are
# already correctly excluded from this export by the "where.not(order_number:
# [nil, ''])" clause — the blank-exclusion test below confirms this against
# real fixture data rather than only against a component created in-test.

require "test_helper"
require "csv"

class UnvalidatedOrderNumbersExportServiceTest < ActiveSupport::TestCase
  def setup
    @owner          = owners(:three)
    @component_type = component_types(:memory_board)
  end

  test "includes a component with a non-blank, unverified order_number" do
    component = Component.create!(
      owner:                  @owner,
      component_type:         @component_type,
      order_number:           "XYZ-#{SecureRandom.hex(4)}",
      order_number_verified:  false,
      serial_number:          "SN-#{SecureRandom.hex(4)}",
      description:            "Test component for export"
    )

    csv = CSV.parse(UnvalidatedOrderNumbersExportService.export, headers: true)
    row = csv.find { |r| r["order_number"] == component.order_number }

    assert row, "Expected the component's order_number to appear in the export"
    assert_equal @component_type.name,   row["component_type"]
    assert_equal @owner.user_name,       row["owner"]
    assert_equal component.serial_number, row["serial_number"]
    assert_equal component.description,   row["description"]
  end

  test "excludes a component whose order_number is already verified" do
    component = Component.create!(
      owner:                  @owner,
      component_type:         @component_type,
      order_number:           "VERIFIED-#{SecureRandom.hex(4)}",
      order_number_verified:  true,
      serial_number:          "SN-#{SecureRandom.hex(4)}" # avoids colliding with charlie_vt100_terminal ("-"/"-")
    )

    csv = CSV.parse(UnvalidatedOrderNumbersExportService.export, headers: true)

    assert_nil csv.find { |r| r["order_number"] == component.order_number },
               "A verified component's order_number should not appear in the unvalidated export"
  end

  test "excludes components with a blank order_number" do
    # Confirmed against real fixture data: every components.yml fixture has a
    # blank order_number, so none of them should ever appear in this export.
    blank_order_number_ids = Component.where(order_number: [nil, ""]).pluck(:id)
    assert blank_order_number_ids.any?,
           "Fixture data must include at least one component with a blank order_number for this test to be meaningful"

    csv = CSV.parse(UnvalidatedOrderNumbersExportService.export, headers: true)
    exported_component_order_number_rows = csv.map { |r| r["order_number"] }

    assert_not exported_component_order_number_rows.include?(nil),
               "No row should correspond to a component with a blank order_number"
  end

  test "includes one row per component even when the same order_number repeats" do
    shared_order_number = "SHARED-#{SecureRandom.hex(4)}"
    Component.create!(owner: @owner, component_type: @component_type,
                       order_number: shared_order_number, order_number_verified: false,
                       serial_number: "SN-#{SecureRandom.hex(4)}") # avoids colliding with charlie_vt100_terminal ("-"/"-")
    Component.create!(owner: @owner, component_type: @component_type,
                       order_number: shared_order_number, order_number_verified: false,
                       serial_number: "SN-#{SecureRandom.hex(4)}")

    csv = CSV.parse(UnvalidatedOrderNumbersExportService.export, headers: true)
    matching_rows = csv.select { |r| r["order_number"] == shared_order_number }

    assert_equal 2, matching_rows.size,
                 "Expected one row per component — the export must not deduplicate by order_number"
  end

  test "orders rows by component id (creation order)" do
    older = Component.create!(owner: @owner, component_type: @component_type,
                               order_number: "ORD-A-#{SecureRandom.hex(4)}", order_number_verified: false,
                               serial_number: "SN-A-#{SecureRandom.hex(4)}")
    newer = Component.create!(owner: @owner, component_type: @component_type,
                               order_number: "ORD-B-#{SecureRandom.hex(4)}", order_number_verified: false,
                               serial_number: "SN-B-#{SecureRandom.hex(4)}")

    csv = CSV.parse(UnvalidatedOrderNumbersExportService.export, headers: true)
    older_index = csv.find_index { |r| r["order_number"] == older.order_number }
    newer_index = csv.find_index { |r| r["order_number"] == newer.order_number }

    assert older_index < newer_index,
           "The component created first (lower id) must appear before the one created after it"
  end
end
