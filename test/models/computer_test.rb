# decor/test/models/computer_test.rb
# version 1.7
# v1.7 (Session 41): Appliances → Peripherals merger Phase 1.
#   Removed all device_type_appliance? tests (enum value no longer exists).
#   Rewrote device_type scope and predicate tests to use peripheral:
#     - "device_type can be set to peripheral" replaces the appliance equivalent
#     - "device_type_peripheral? is true for peripheral fixture" (dec_unibus_router,
#       formerly appliance, now peripheral after fixture v1.9 change)
#     - "device_type_computer scope excludes peripherals" replaces appliance version
#     - "device_type_peripheral scope excludes computers" replaces appliance version
#   dec_unibus_router fixture is still used in barter_status tests (unchanged).
# v1.6 (Session 28): Added serial_number uniqueness validation tests.
# v1.5 (Session 22): Added barter_status enum tests.
# v1.4: Added device_type enum tests.

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

  # --- serial_number uniqueness validation tests (Session 28) ---
  # Constraint scope: (owner_id, computer_model_id, serial_number).

  test "valid when serial_number is unique within owner and model" do
    computer = Computer.new(
      owner: owners(:one),
      computer_model: computer_models(:pdp11_70),
      serial_number: "UNIQ-SN-001"
    )
    assert computer.valid?, "A unique serial number must be valid: #{computer.errors.full_messages}"
  end

  test "invalid when same owner has duplicate serial number on same model" do
    Computer.create!(
      owner: owners(:one),
      computer_model: computer_models(:vt100),
      serial_number: "DUPE-SN-001"
    )

    duplicate = Computer.new(
      owner: owners(:one),       # same owner
      computer_model: computer_models(:vt100),
      serial_number: "DUPE-SN-001"
    )
    assert_not duplicate.valid?,
                "Same owner + same model + same serial must be invalid"
    assert duplicate.errors[:serial_number].any?,
           "Validation error must be on serial_number"
  end

  test "same owner may use the same serial number on different models" do
    # A VT220 "unknown" and a VT320 "unknown" owned by the same person are
    # physically different devices — both must be valid.
    Computer.create!(
      owner: owners(:one),
      computer_model: computer_models(:vt100),
      serial_number: "SHARED-SN-001"
    )

    different_model = Computer.new(
      owner: owners(:one),
      computer_model: computer_models(:pdp11_70),  # different model
      serial_number: "SHARED-SN-001"
    )
    assert different_model.valid?,
           "Same owner + different model + same serial must be valid"
  end

  test "different owner may use the same serial number on the same model" do
    # Owners invent their own numbering schemes; cross-owner collisions are expected.
    Computer.create!(
      owner: owners(:one),       # alice
      computer_model: computer_models(:vt100),
      serial_number: "CROSS-OWNER-SN"
    )

    bob_computer = Computer.new(
      owner: owners(:two),       # bob — different owner, same model+serial
      computer_model: computer_models(:vt100),
      serial_number: "CROSS-OWNER-SN"
    )
    assert bob_computer.valid?,
           "Different owner + same model + same serial must be valid"
  end

  test "duplicate serial number error message is descriptive" do
    Computer.create!(
      owner: owners(:one),
      computer_model: computer_models(:pdp11_70),
      serial_number: "ERR-MSG-SN-001"
    )

    duplicate = Computer.new(
      owner: owners(:one),
      computer_model: computer_models(:pdp11_70),
      serial_number: "ERR-MSG-SN-001"
    )
    duplicate.valid?
    assert_match "model", duplicate.errors[:serial_number].first,
                 "Error message must mention 'model' to help the user understand the constraint"
  end

  # --- device_type enum tests ---

  test "device_type defaults to computer" do
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
    assert_not computer.device_type_peripheral?
  end

  test "device_type can be set to peripheral" do
    computer = Computer.new(
      owner: owners(:one),
      computer_model: computer_models(:pdp11_70),
      serial_number: "TEST-SN-DTYPE-003",
      device_type: :peripheral
    )
    assert_equal "peripheral", computer.device_type
    assert computer.device_type_peripheral?
    assert_not computer.device_type_computer?
  end

  test "device_type_peripheral? is true for peripheral fixture" do
    # dec_unibus_router was formerly an appliance fixture (device_type: 1);
    # it is now a peripheral fixture (device_type: 2) after the Session 41 merger.
    peripheral = computers(:dec_unibus_router)
    assert peripheral.device_type_peripheral?
    assert_not peripheral.device_type_computer?
  end

  test "device_type_computer scope excludes peripherals" do
    computers = Computer.device_type_computer
    assert_not computers.exists?(computers(:dec_unibus_router).id),
      "device_type_computer scope must not include peripherals"
  end

  test "device_type_peripheral scope excludes computers" do
    peripherals = Computer.device_type_peripheral
    assert peripherals.exists?(computers(:dec_unibus_router).id),
      "device_type_peripheral scope must include the peripheral fixture"
    assert_not peripherals.exists?(computers(:alice_pdp11).id),
      "device_type_peripheral scope must not include computers"
  end

  # --- barter_status enum tests ---

  test "barter_status defaults to no_barter" do
    computer = Computer.new(
      owner: owners(:one),
      computer_model: computer_models(:pdp11_70),
      serial_number: "TEST-SN-BARTER-001"
    )
    assert_equal "no_barter", computer.barter_status
  end

  test "barter_status_no_barter? is true for default record" do
    computer = Computer.new(
      owner: owners(:one),
      computer_model: computer_models(:pdp11_70),
      serial_number: "TEST-SN-BARTER-002"
    )
    assert computer.barter_status_no_barter?
    assert_not computer.barter_status_offered?
    assert_not computer.barter_status_wanted?
  end

  test "barter_status can be set to offered" do
    computer = Computer.new(
      owner: owners(:one),
      computer_model: computer_models(:pdp11_70),
      serial_number: "TEST-SN-BARTER-003",
      barter_status: :offered
    )
    assert_equal "offered", computer.barter_status
    assert computer.barter_status_offered?
    assert_not computer.barter_status_no_barter?
    assert_not computer.barter_status_wanted?
  end

  test "barter_status can be set to wanted" do
    computer = Computer.new(
      owner: owners(:one),
      computer_model: computer_models(:pdp11_70),
      serial_number: "TEST-SN-BARTER-004",
      barter_status: :wanted
    )
    assert_equal "wanted", computer.barter_status
    assert computer.barter_status_wanted?
    assert_not computer.barter_status_no_barter?
    assert_not computer.barter_status_offered?
  end

  test "alice_vax fixture has barter_status wanted" do
    vax = computers(:alice_vax)
    assert_equal "wanted", vax.barter_status
    assert vax.barter_status_wanted?
  end

  test "dec_unibus_router fixture has barter_status offered" do
    router = computers(:dec_unibus_router)
    assert_equal "offered", router.barter_status
    assert router.barter_status_offered?
  end

  test "alice_pdp11 fixture has barter_status no_barter" do
    pdp11 = computers(:alice_pdp11)
    assert_equal "no_barter", pdp11.barter_status
    assert pdp11.barter_status_no_barter?
  end
end
