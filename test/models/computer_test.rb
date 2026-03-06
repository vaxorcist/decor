# decor/test/models/computer_test.rb
# version 1.4
# Added: device_type enum tests — default, predicates, and scope filtering.

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

  test "destroying a computer destroys its components" do
    # alice_pdp11 has two components in fixtures: pdp11_memory and pdp11_cpu.
    # Verifies that dependent: :destroy cascades — no orphaned components remain.
    computer = computers(:alice_pdp11)
    component_ids = computer.components.pluck(:id)
    assert component_ids.any?, "Fixture must have at least one component for this test to be meaningful"

    computer.destroy
    surviving = Component.where(id: component_ids).count
    assert_equal 0, surviving, "Expected all components to be destroyed with the computer"
  end

  # --- device_type enum tests ---

  test "device_type defaults to computer" do
    # A new record without an explicit device_type must default to computer (0).
    computer = Computer.new(
      owner: owners(:one),
      computer_model: computer_models(:pdp11_70),
      serial_number: "TEST-SN-DTYPE-001"
    )
    assert_equal "computer", computer.device_type
  end

  test "device_type_computer? is true for default record" do
    computer = Computer.new(
      owner: owners(:one),
      computer_model: computer_models(:pdp11_70),
      serial_number: "TEST-SN-DTYPE-002"
    )
    assert computer.device_type_computer?
    assert_not computer.device_type_appliance?
  end

  test "device_type can be set to appliance" do
    computer = Computer.new(
      owner: owners(:one),
      computer_model: computer_models(:pdp11_70),
      serial_number: "TEST-SN-DTYPE-003",
      device_type: :appliance
    )
    assert_equal "appliance", computer.device_type
    assert computer.device_type_appliance?
    assert_not computer.device_type_computer?
  end

  test "device_type_appliance? is true for appliance fixture" do
    # dec_unibus_router fixture has device_type: 1 (appliance).
    appliance = computers(:dec_unibus_router)
    assert appliance.device_type_appliance?
    assert_not appliance.device_type_computer?
  end

  test "device_type_computer scope excludes appliances" do
    # The dec_unibus_router fixture is an appliance and must not appear in this scope.
    computers = Computer.device_type_computer
    assert_not computers.exists?(computers(:dec_unibus_router).id),
      "device_type_computer scope must not include appliances"
  end

  test "device_type_appliance scope excludes computers" do
    # alice_pdp11 is a computer and must not appear in the appliance scope.
    appliances = Computer.device_type_appliance
    assert appliances.exists?(computers(:dec_unibus_router).id),
      "device_type_appliance scope must include the appliance fixture"
    assert_not appliances.exists?(computers(:alice_pdp11).id),
      "device_type_appliance scope must not include computers"
  end
end
