# decor/test/models/computer_model_test.rb
# version 1.3
# v1.3 (Session 41): Appliances → Peripherals merger Phase 1.
#   Removed all device_type_appliance? tests (enum value no longer exists).
#   Rewrote predicate and scope tests to use peripheral:
#     - "device_type_peripheral? returns true for peripheral fixture" replaces
#       the appliance equivalent; uses hsc50 (formerly appliance, now peripheral).
#     - "device_type_computer scope excludes peripheral models" replaces appliance version.
#     - "device_type_computer and device_type_peripheral scopes are disjoint" replaces
#       the appliance version.
# v1.2: Added device_type enum tests: default value, predicates, scopes.
#   Pattern mirrors computer_test.rb v1.4 (Session 13).

require "test_helper"

class ComputerModelTest < ActiveSupport::TestCase
  # ── Existing validations ─────────────────────────────────────────────────

  test "valid with name" do
    model = ComputerModel.new(name: "PDP-11/44")
    assert model.valid?
  end

  test "invalid without name" do
    model = ComputerModel.new(name: nil)
    assert_not model.valid?
    assert_includes model.errors[:name], "can't be blank"
  end

  test "invalid with duplicate name" do
    model = ComputerModel.new(name: computer_models(:pdp11_70).name)
    assert_not model.valid?
    assert_includes model.errors[:name], "has already been taken"
  end

  # ── device_type enum — default ────────────────────────────────────────────

  test "device_type defaults to computer (0)" do
    model = ComputerModel.create!(name: "PDP-11/34")
    assert_equal "computer", model.device_type
    assert model.device_type_computer?
    assert_not model.device_type_peripheral?
  end

  # ── device_type enum — predicates ────────────────────────────────────────

  test "device_type_computer? returns true for computer fixture" do
    model = computer_models(:pdp11_70)
    assert model.device_type_computer?
    assert_not model.device_type_peripheral?
  end

  test "device_type_peripheral? returns true for peripheral fixture" do
    # hsc50 was formerly an appliance fixture (device_type: 1);
    # it is now a peripheral fixture (device_type: 2) after the Session 41 merger.
    model = computer_models(:hsc50)
    assert model.device_type_peripheral?
    assert_not model.device_type_computer?
  end

  # ── device_type enum — scopes ─────────────────────────────────────────────

  test "device_type_computer scope excludes peripheral models" do
    computer_ids   = ComputerModel.device_type_computer.pluck(:id)
    peripheral_ids = ComputerModel.device_type_peripheral.pluck(:id)

    assert_includes computer_ids,  computer_models(:pdp11_70).id
    assert_not_includes computer_ids, computer_models(:hsc50).id

    assert_includes peripheral_ids, computer_models(:hsc50).id
    assert_not_includes peripheral_ids, computer_models(:pdp11_70).id
  end

  test "device_type_computer and device_type_peripheral scopes are disjoint" do
    computer_ids   = ComputerModel.device_type_computer.pluck(:id)
    peripheral_ids = ComputerModel.device_type_peripheral.pluck(:id)

    assert_empty computer_ids & peripheral_ids,
                 "computer and peripheral scopes must not overlap"
  end
end
