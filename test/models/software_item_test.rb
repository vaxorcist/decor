# decor/test/models/software_item_test.rb
# version 1.0
# Session 43: Model tests for SoftwareItem.
#   Covers: fixture validity, required/optional associations, field length
#   validations, barter_status enum values and default, and the cascade
#   behaviour when the parent computer is deleted.

require "test_helper"

class SoftwareItemTest < ActiveSupport::TestCase
  def setup
    @alice_vms        = software_items(:alice_vms)         # installed, with condition
    @alice_rt11_spare = software_items(:alice_rt11_spare)  # unattached, no condition
    @charlie_rt11     = software_items(:charlie_rt11)       # neutral owner, wanted
  end

  # --- Fixture sanity ---

  test "alice_vms fixture is valid" do
    assert @alice_vms.valid?
  end

  test "alice_rt11_spare fixture without computer is valid" do
    assert @alice_rt11_spare.valid?
  end

  test "charlie_rt11 fixture is valid" do
    assert @charlie_rt11.valid?
  end

  # --- Required associations ---

  test "owner is required" do
    @alice_vms.owner = nil
    assert_not @alice_vms.valid?
    assert @alice_vms.errors[:owner].any?
  end

  test "software_name is required" do
    @alice_vms.software_name = nil
    assert_not @alice_vms.valid?
    assert @alice_vms.errors[:software_name].any?
  end

  # --- Optional associations ---

  test "computer is optional" do
    @alice_vms.computer = nil
    assert @alice_vms.valid?
  end

  test "software_condition is optional" do
    @alice_vms.software_condition = nil
    assert @alice_vms.valid?
  end

  # --- version: optional length ---

  test "version can be blank" do
    @alice_vms.version = ""
    assert @alice_vms.valid?
  end

  test "version can be nil" do
    @alice_vms.version = nil
    assert @alice_vms.valid?
  end

  test "version at exactly 20 characters is valid" do
    @alice_vms.version = "A" * 20
    assert @alice_vms.valid?
  end

  test "version at 21 characters is invalid" do
    @alice_vms.version = "A" * 21
    assert_not @alice_vms.valid?
    assert @alice_vms.errors[:version].any?
  end

  # --- description: optional length ---

  test "description can be blank" do
    @alice_vms.description = ""
    assert @alice_vms.valid?
  end

  test "description at exactly 100 characters is valid" do
    @alice_vms.description = "A" * 100
    assert @alice_vms.valid?
  end

  test "description at 101 characters is invalid" do
    @alice_vms.description = "A" * 101
    assert_not @alice_vms.valid?
    assert @alice_vms.errors[:description].any?
  end

  # --- history: optional length ---

  test "history can be blank" do
    @alice_vms.history = ""
    assert @alice_vms.valid?
  end

  test "history at exactly 200 characters is valid" do
    @alice_vms.history = "A" * 200
    assert @alice_vms.valid?
  end

  test "history at 201 characters is invalid" do
    @alice_vms.history = "A" * 201
    assert_not @alice_vms.valid?
    assert @alice_vms.errors[:history].any?
  end

  # --- barter_status enum ---

  test "barter_status defaults to no_barter" do
    item = SoftwareItem.new
    assert_equal "no_barter", item.barter_status
  end

  test "alice_vms barter_status is no_barter" do
    assert_equal "no_barter", @alice_vms.barter_status
    assert @alice_vms.barter_status_no_barter?
  end

  test "alice_rt11_spare barter_status is offered" do
    assert_equal "offered", @alice_rt11_spare.barter_status
    assert @alice_rt11_spare.barter_status_offered?
  end

  test "charlie_rt11 barter_status is wanted" do
    assert_equal "wanted", @charlie_rt11.barter_status
    assert @charlie_rt11.barter_status_wanted?
  end

  # --- cascade: deleting a computer destroys its software items ---

  test "software items are destroyed when computer is deleted" do
    # Identify all software_items installed on alice's pdp11 before deletion.
    computer = computers(:alice_pdp11)
    installed_ids = computer.software_items.pluck(:id)

    assert installed_ids.any?, "alice_pdp11 must have at least one software item for this test"

    computer.destroy

    installed_ids.each do |id|
      assert_nil SoftwareItem.find_by(id: id),
                 "SoftwareItem #{id} should have been destroyed with the computer"
    end
  end

  # --- unattached software is not affected by computer deletion ---

  test "unattached software items survive computer deletion" do
    spare_id = @alice_rt11_spare.id
    assert_nil @alice_rt11_spare.computer_id, "spare must have no computer for this test"

    # Destroying any computer must not affect the unattached spare.
    computers(:alice_pdp11).destroy

    assert SoftwareItem.exists?(spare_id),
           "Unattached software item should not be deleted when a computer is destroyed"
  end

  # --- minimal valid record ---

  test "can create with only owner and software_name" do
    item = SoftwareItem.new(
      owner:         owners(:one),
      software_name: software_names(:vms)
    )
    assert item.valid?
  end
end
