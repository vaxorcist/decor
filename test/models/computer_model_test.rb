# decor/test/models/computer_model_test.rb
# version 1.2
# Added device_type enum tests: default value, predicates, scopes.
# Pattern mirrors computer_test.rb v1.4 (Session 13).

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
    assert_not model.device_type_appliance?
  end

  # ── device_type enum — predicates ────────────────────────────────────────

  test "device_type_computer? returns true for computer fixture" do
    model = computer_models(:pdp11_70)
    assert model.device_type_computer?
    assert_not model.device_type_appliance?
  end

  test "device_type_appliance? returns true for appliance fixture" do
    model = computer_models(:hsc50)
    assert model.device_type_appliance?
    assert_not model.device_type_computer?
  end

  # ── device_type enum — scopes ─────────────────────────────────────────────

  test "device_type_computer scope excludes appliance models" do
    computer_ids  = ComputerModel.device_type_computer.pluck(:id)
    appliance_ids = ComputerModel.device_type_appliance.pluck(:id)

    assert_includes computer_ids,  computer_models(:pdp11_70).id
    assert_not_includes computer_ids, computer_models(:hsc50).id

    assert_includes appliance_ids, computer_models(:hsc50).id
    assert_not_includes appliance_ids, computer_models(:pdp11_70).id
  end

  test "device_type_computer and device_type_appliance scopes are disjoint" do
    computer_ids  = ComputerModel.device_type_computer.pluck(:id)
    appliance_ids = ComputerModel.device_type_appliance.pluck(:id)

    assert_empty computer_ids & appliance_ids,
                 "computer and appliance scopes must not overlap"
  end
end
