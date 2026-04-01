# decor/test/models/software_name_test.rb
# version 1.0
# Session 43: Model tests for SoftwareName — admin-managed lookup table.
#   Covers: fixture validity, name presence/uniqueness/length, description
#   optional length, and restrict_with_error when items reference the name.

require "test_helper"

class SoftwareNameTest < ActiveSupport::TestCase
  def setup
    @vms   = software_names(:vms)
    @tops20 = software_names(:tops20)  # no description fixture
  end

  # --- Fixture sanity ---

  test "vms fixture is valid" do
    assert @vms.valid?
  end

  test "tops20 fixture without description is valid" do
    assert @tops20.valid?
  end

  # --- name: presence ---

  test "name must be present" do
    @vms.name = ""
    assert_not @vms.valid?
    assert @vms.errors[:name].any?
  end

  test "name cannot be nil" do
    @vms.name = nil
    assert_not @vms.valid?
    assert @vms.errors[:name].any?
  end

  # --- name: uniqueness ---

  test "name must be unique" do
    duplicate = SoftwareName.new(name: @vms.name)
    assert_not duplicate.valid?
    assert duplicate.errors[:name].any?
  end

  test "different names are valid" do
    sn = SoftwareName.new(name: "TOPS-10")
    assert sn.valid?
  end

  # --- name: length ---

  test "name at exactly 40 characters is valid" do
    @vms.name = "A" * 40
    assert @vms.valid?
  end

  test "name at 41 characters is invalid" do
    @vms.name = "A" * 41
    assert_not @vms.valid?
    assert @vms.errors[:name].any?
  end

  # --- description: optional length ---

  test "description can be blank" do
    @vms.description = ""
    assert @vms.valid?
  end

  test "description can be nil" do
    @vms.description = nil
    assert @vms.valid?
  end

  test "description at exactly 100 characters is valid" do
    @vms.description = "A" * 100
    assert @vms.valid?
  end

  test "description at 101 characters is invalid" do
    @vms.description = "A" * 101
    assert_not @vms.valid?
    assert @vms.errors[:description].any?
  end

  # --- associations ---

  test "has many software items" do
    assert_respond_to @vms, :software_items
  end

  # restrict_with_error: cannot destroy a name that is referenced by a software item.
  # alice_vms fixture references software_names(:vms).
  test "cannot be destroyed when software items reference it" do
    assert_not @vms.destroy
    assert @vms.errors[:base].any?
    assert SoftwareName.exists?(@vms.id), "vms should still exist after failed destroy"
  end

  # A name with no referencing items can be destroyed.
  test "can be destroyed when no software items reference it" do
    name = SoftwareName.create!(name: "ULTRIX")
    assert name.destroy
    assert_not SoftwareName.exists?(name.id)
  end
end
