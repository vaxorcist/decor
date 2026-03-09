# decor/test/models/component_test.rb
# version 1.4
# v1.4 (Session 22): Added barter_status enum tests — default, predicates,
#   fixture values (spare_disk: wanted, charlie_vt100_terminal: offered, others: no_barter).
#   Pattern mirrors component_category tests above.
# v1.3: Fixed: bob_vt100_terminal → charlie_vt100_terminal to match fixture rename.
# The peripheral fixture was moved to owner three (charlie) to avoid breaking
# both OwnerExportServiceTest (alice count) and OwnersControllerDestroyTest
# (bob count).

require "test_helper"

class ComponentTest < ActiveSupport::TestCase
  test "valid with required attributes" do
    component = Component.new(
      owner: owners(:one),
      component_type: component_types(:memory_board)
    )
    assert component.valid?
  end

  test "valid with optional computer" do
    component = Component.new(
      owner: owners(:one),
      computer: computers(:alice_pdp11),
      component_type: component_types(:memory_board)
    )
    assert component.valid?
  end

  test "valid without computer (spare component)" do
    component = Component.new(
      owner: owners(:one),
      computer: nil,
      component_type: component_types(:disk_drive),
      description: "Spare drive"
    )
    assert component.valid?
  end

  test "invalid without owner" do
    component = Component.new(
      component_type: component_types(:memory_board)
    )
    assert_not component.valid?
    assert_includes component.errors[:owner], "must exist"
  end

  test "invalid without component_type" do
    component = Component.new(
      owner: owners(:one)
    )
    assert_not component.valid?
    assert_includes component.errors[:component_type], "must exist"
  end

  test "belongs to owner" do
    component = components(:pdp11_memory)
    assert_equal owners(:one), component.owner
  end

  test "belongs to computer (optional)" do
    component = components(:pdp11_memory)
    assert_equal computers(:alice_pdp11), component.computer
  end

  test "spare component has no computer" do
    component = components(:spare_disk)
    assert_nil component.computer
  end

  test "belongs to component_type" do
    component = components(:pdp11_memory)
    assert_equal component_types(:memory_board), component.component_type
  end

  # --- component_category enum tests ---

  test "component_category defaults to integral" do
    # A new record without an explicit component_category must default to integral (0).
    component = Component.new(
      owner: owners(:one),
      component_type: component_types(:memory_board)
    )
    assert_equal "integral", component.component_category
  end

  test "component_category_integral? is true for default record" do
    component = Component.new(
      owner: owners(:one),
      component_type: component_types(:memory_board)
    )
    assert component.component_category_integral?
    assert_not component.component_category_peripheral?
  end

  test "component_category can be set to peripheral" do
    component = Component.new(
      owner: owners(:one),
      component_type: component_types(:memory_board),
      component_category: :peripheral
    )
    assert_equal "peripheral", component.component_category
    assert component.component_category_peripheral?
    assert_not component.component_category_integral?
  end

  test "existing integral fixtures have category integral" do
    # pdp11_memory and pdp11_cpu omit component_category in the fixture,
    # so they receive the DB default (0 = integral).
    assert components(:pdp11_memory).component_category_integral?
    assert components(:pdp11_cpu).component_category_integral?
  end

  test "peripheral fixture has category peripheral" do
    # charlie_vt100_terminal fixture has component_category: 1 (peripheral).
    terminal = components(:charlie_vt100_terminal)
    assert terminal.component_category_peripheral?
    assert_not terminal.component_category_integral?
  end

  test "spare component can be integral" do
    # Spare status (computer_id IS NULL) is orthogonal to category.
    # spare_disk omits component_category, so it defaults to integral.
    spare = components(:spare_disk)
    assert_nil spare.computer
    assert spare.component_category_integral?,
      "A spare component with no category set should default to integral"
  end

  test "spare component can be peripheral" do
    # Explicitly building a spare peripheral — computer_id nil, category peripheral.
    spare_peripheral = Component.new(
      owner: owners(:one),
      computer: nil,
      component_type: component_types(:memory_board),
      component_category: :peripheral,
      description: "Spare terminal not yet connected"
    )
    assert spare_peripheral.valid?
    assert_nil spare_peripheral.computer
    assert spare_peripheral.component_category_peripheral?
  end

  # --- barter_status enum tests ---

  test "barter_status defaults to no_barter" do
    # A new record without an explicit barter_status must default to no_barter (0).
    component = Component.new(
      owner: owners(:one),
      component_type: component_types(:memory_board)
    )
    assert_equal "no_barter", component.barter_status
  end

  test "barter_status_no_barter? is true for default record" do
    component = Component.new(
      owner: owners(:one),
      component_type: component_types(:memory_board)
    )
    assert component.barter_status_no_barter?
    assert_not component.barter_status_offered?
    assert_not component.barter_status_wanted?
  end

  test "barter_status can be set to offered" do
    component = Component.new(
      owner: owners(:one),
      component_type: component_types(:memory_board),
      barter_status: :offered
    )
    assert_equal "offered", component.barter_status
    assert component.barter_status_offered?
    assert_not component.barter_status_no_barter?
    assert_not component.barter_status_wanted?
  end

  test "barter_status can be set to wanted" do
    component = Component.new(
      owner: owners(:one),
      component_type: component_types(:memory_board),
      barter_status: :wanted
    )
    assert_equal "wanted", component.barter_status
    assert component.barter_status_wanted?
    assert_not component.barter_status_no_barter?
    assert_not component.barter_status_offered?
  end

  test "spare_disk fixture has barter_status wanted" do
    # spare_disk was set to barter_status: 2 (wanted) in components.yml v1.4.
    spare = components(:spare_disk)
    assert_equal "wanted", spare.barter_status
    assert spare.barter_status_wanted?
  end

  test "charlie_vt100_terminal fixture has barter_status offered" do
    # charlie_vt100_terminal was set to barter_status: 1 (offered) in components.yml v1.4.
    terminal = components(:charlie_vt100_terminal)
    assert_equal "offered", terminal.barter_status
    assert terminal.barter_status_offered?
  end

  test "pdp11_memory fixture has barter_status no_barter" do
    # pdp11_memory omits barter_status in the fixture, so it receives the DB default (0).
    memory = components(:pdp11_memory)
    assert_equal "no_barter", memory.barter_status
    assert memory.barter_status_no_barter?
  end
end
