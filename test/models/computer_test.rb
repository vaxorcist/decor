# decor/test/models/computer_test.rb
# version 1.2
# Updated all references following the conditions → computer_conditions rename:
#   conditions(:label)        → computer_conditions(:label)
#   condition: ...            → computer_condition: ...
#   computer.condition        → computer.computer_condition
#   Condition class           → ComputerCondition class
#   "belongs to condition"    → "belongs to computer_condition"
#   "condition returns name"  → "computer_condition returns name"

require "test_helper"

class ComputerTest < ActiveSupport::TestCase
  test "valid with required attributes" do
    computer = Computer.new(
      owner: owners(:one),
      computer_model: computer_models(:pdp11_70),
      serial_number: "TEST-SN-001",
      computer_condition: computer_conditions(:original),
      run_status: run_statuses(:unknown)
    )
    assert computer.valid?
  end

  test "invalid without owner" do
    computer = Computer.new(
      computer_model: computer_models(:pdp11_70),
      serial_number: "TEST-SN-002",
      computer_condition: computer_conditions(:original),
      run_status: run_statuses(:unknown)
    )
    assert_not computer.valid?
    assert_includes computer.errors[:owner], "must exist"
  end

  test "invalid without computer_model" do
    computer = Computer.new(
      owner: owners(:one),
      serial_number: "TEST-SN-003",
      computer_condition: computer_conditions(:original),
      run_status: run_statuses(:unknown)
    )
    assert_not computer.valid?
    assert_includes computer.errors[:computer_model], "must exist"
  end

  test "valid without condition" do
    computer = Computer.new(
      owner: owners(:one),
      computer_model: computer_models(:pdp11_70),
      serial_number: "TEST-SN-004",
      run_status: run_statuses(:unknown)
    )
    assert computer.valid?
  end

  test "valid without run_status" do
    computer = Computer.new(
      owner: owners(:one),
      computer_model: computer_models(:pdp11_70),
      serial_number: "TEST-SN-005",
      computer_condition: computer_conditions(:original)
    )
    assert computer.valid?
  end

  test "computer_condition returns name" do
    computer = computers(:alice_pdp11)
    assert_equal "Completely original", computer.computer_condition.name
  end

  test "run_status returns name" do
    computer = computers(:bob_pdp8)
    assert_equal "Working with a few problems", computer.run_status.name
  end

  test "has many components" do
    computer = computers(:alice_pdp11)
    assert_respond_to computer, :components
  end

  test "belongs to computer_condition" do
    computer = computers(:alice_pdp11)
    assert_respond_to computer, :computer_condition
    assert_instance_of ComputerCondition, computer.computer_condition
  end

  test "belongs to run_status" do
    computer = computers(:alice_pdp11)
    assert_respond_to computer, :run_status
    assert_instance_of RunStatus, computer.run_status
  end
end
