# decor/test/models/component_test.rb
# version 1.3
# Fixed: bob_vt100_terminal → charlie_vt100_terminal to match fixture rename.
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
end
