# decor/test/models/storage_location_test.rb
# version 1.0
# Session A (Storage Locations feature, Part 1 of 6).
#
# Coverage:
#   - name presence (nil and blank)
#   - name max length (50) — boundary tests at exactly 50 and 51
#   - name uniqueness scoped to owner (two owners may share the same name;
#     the same owner may not have two locations with the same name)
#   - belongs_to :owner association
#
# NOT YET COVERED (deferred to Session C, once has_many :computers /
# :components / :software_items with dependent: :nullify exists on this
# model — those associations don't exist yet because the referencing tables
# don't have a storage_location_id column until Session C's migration runs):
#   - nullify behaviour when a storage_location with assigned items is destroyed
#   - the owner-facing delete-confirmation warning (Session B)
#
# Fixtures:
#   storage_locations(:alice_attic) — owner one (alice), name "Attic Shelf 3"
#   storage_locations(:bob_garage)  — owner two (bob),   name "Garage Box B"

require "test_helper"

class StorageLocationTest < ActiveSupport::TestCase
  # -------------------------------------------------------------------------
  # name — presence
  # -------------------------------------------------------------------------

  test "invalid without a name" do
    location = StorageLocation.new(owner: owners(:one), name: nil)
    assert_not location.valid?
    assert location.errors[:name].any?,
           "A storage location with no name must be invalid"
  end

  test "invalid with a blank name" do
    location = StorageLocation.new(owner: owners(:one), name: "")
    assert_not location.valid?
    assert location.errors[:name].any?,
           "A storage location with a blank name must be invalid"
  end

  # -------------------------------------------------------------------------
  # name — max length (50)
  # -------------------------------------------------------------------------

  test "valid when name is exactly 50 characters" do
    location = StorageLocation.new(owner: owners(:one), name: "x" * 50)
    assert location.valid?,
           "A name of exactly 50 characters must be valid: #{location.errors.full_messages}"
  end

  test "invalid when name exceeds 50 characters" do
    location = StorageLocation.new(owner: owners(:one), name: "x" * 51)
    assert_not location.valid?
    assert location.errors[:name].any?,
           "A name longer than 50 characters must make the location invalid"
  end

  # -------------------------------------------------------------------------
  # name — uniqueness scoped to owner
  # -------------------------------------------------------------------------

  test "invalid when name duplicates an existing location for the same owner" do
    existing = storage_locations(:alice_attic)
    duplicate = StorageLocation.new(owner: existing.owner, name: existing.name)
    assert_not duplicate.valid?
    assert duplicate.errors[:name].any?,
           "A duplicate name for the same owner must be invalid"
  end

  test "valid when name duplicates an existing location for a different owner" do
    # alice_attic (owner one) is named "Attic Shelf 3" — bob (owner two) must
    # be allowed to use the exact same name, since uniqueness is per owner,
    # not global.
    existing = storage_locations(:alice_attic)
    same_name_different_owner = StorageLocation.new(owner: owners(:two), name: existing.name)
    assert same_name_different_owner.valid?,
           "The same name must be allowed for a different owner: " \
           "#{same_name_different_owner.errors.full_messages}"
  end

  # -------------------------------------------------------------------------
  # Associations
  # -------------------------------------------------------------------------

  test "belongs to owner" do
    location = storage_locations(:alice_attic)
    assert_respond_to location, :owner
    assert_equal owners(:one), location.owner,
                 "alice_attic must belong to owner one (alice)"
  end
end
