# decor/test/models/connection_group_test.rb
# version 1.2
# v1.2 (Session 39): Added five tests for Session 38 additions:
#   - no_duplicate_computers group-level validator (in-memory duplicate detection)
#   - owner_group_id auto-assign when left blank (owner has no existing groups)
#   - owner_group_id auto-assigns as max+1 when owner already has groups
#   - owner_group_id uniqueness is scoped per owner (two owners may share the same value)
#   - label over 100 characters is invalid
# v1.1 (Session 32): Fixed error key for minimum_two_members assertions.
#   Model adds error on :connection_members (not :base). Two assertions updated.
#   all_members_belong_to_owner still correctly asserts :base — unchanged.
# Session 32 (Part 1b): Model tests for ConnectionGroup.
#
# Coverage:
#   - minimum_two_members custom validation (0, 1, 2 member boundary)
#   - all_members_belong_to_owner cross-owner guard
#   - no_duplicate_computers group-level validator (Session 39)
#   - connection_type is optional (nullable FK)
#   - owner_group_id auto-assign + uniqueness (Session 39)
#   - label max 100 characters (Session 39)
#   - belongs_to :owner, :connection_type associations
#   - has_many :connection_members and :computers (through) associations
#   - dependent: :delete_all — destroy group → all members deleted from DB
#   - computers themselves are NOT destroyed when the group is destroyed
#
# Fixtures:
#   connection_groups(:bob_pdp8_vt100)   — owner two (bob), type rs232, 2 members, owner_group_id: 1
#   connection_groups(:alice_pdp11_vax)  — owner one (alice), no type, 2 members, owner_group_id: 1
#
# Note on error keys:
#   minimum_two_members    → :connection_members
#   all_members_belong_to_owner → :base
#   no_duplicate_computers → :base  (group-level, same category as cross-owner guard)

require "test_helper"

class ConnectionGroupTest < ActiveSupport::TestCase
  # -------------------------------------------------------------------------
  # minimum_two_members validation
  # -------------------------------------------------------------------------

  test "valid when group has exactly two members from the same owner" do
    # Boundary: exactly 2 — must pass
    group = ConnectionGroup.new(
      owner: owners(:one),
      connection_members: [
        ConnectionMember.new(computer: computers(:alice_pdp11)),
        ConnectionMember.new(computer: computers(:alice_vax))
      ]
    )
    assert group.valid?,
           "A group with 2 same-owner members must be valid: #{group.errors.full_messages}"
  end

  test "invalid when group has zero members" do
    # Boundary: 0 members — must fail
    group = ConnectionGroup.new(owner: owners(:one))
    assert_not group.valid?
    assert group.errors[:connection_members].any?,
           "minimum_two_members must add an error on :connection_members when there are no members"
  end

  test "invalid when group has only one member" do
    # Boundary: 1 member — must fail (single endpoint is not a connection)
    group = ConnectionGroup.new(
      owner: owners(:one),
      connection_members: [
        ConnectionMember.new(computer: computers(:alice_pdp11))
      ]
    )
    assert_not group.valid?
    assert group.errors[:connection_members].any?,
           "minimum_two_members must add an error on :connection_members with 1 member"
  end

  # -------------------------------------------------------------------------
  # all_members_belong_to_owner validation
  # -------------------------------------------------------------------------

  test "invalid when a member computer belongs to a different owner" do
    # alice's group (owner one) must not contain bob's computer (owner two)
    group = ConnectionGroup.new(
      owner: owners(:one),
      connection_members: [
        ConnectionMember.new(computer: computers(:alice_pdp11)),
        ConnectionMember.new(computer: computers(:bob_pdp8))  # wrong owner
      ]
    )
    assert_not group.valid?,
               "A group must be invalid when a member's computer belongs to a different owner"
    assert group.errors[:base].any?,
           "Cross-owner member error must appear on :base"
  end

  # -------------------------------------------------------------------------
  # no_duplicate_computers group-level validation (Session 38)
  # -------------------------------------------------------------------------

  test "invalid when the same computer is listed twice as members in the same group" do
    # The DB unique index on (connection_group_id, computer_id) would catch
    # this at INSERT time, but raising ActiveRecord::RecordNotUnique produces
    # a confusing error. The no_duplicate_computers validator detects the
    # duplicate in-memory before any SQL runs, producing a friendly error on :base.
    group = ConnectionGroup.new(
      owner: owners(:one),
      connection_members: [
        ConnectionMember.new(computer: computers(:alice_pdp11)),
        ConnectionMember.new(computer: computers(:alice_pdp11))  # same device twice
      ]
    )
    assert_not group.valid?,
               "A group with the same computer listed twice must be invalid"
    assert group.errors[:base].any?,
           "no_duplicate_computers must add an error on :base for an in-memory duplicate"
  end

  # -------------------------------------------------------------------------
  # connection_type optional (nullable FK)
  # -------------------------------------------------------------------------

  test "valid without connection_type" do
    # alice_pdp11_vax has no connection_type_id in the fixture
    group = connection_groups(:alice_pdp11_vax)
    assert_nil group.connection_type_id,
               "alice_pdp11_vax fixture must have no connection_type_id set"
    assert group.valid?,
           "A group with no connection_type must still be valid: #{group.errors.full_messages}"
  end

  test "valid with connection_type set" do
    # bob_pdp8_vt100 has rs232 as its connection_type
    group = connection_groups(:bob_pdp8_vt100)
    assert_not_nil group.connection_type,
                   "bob_pdp8_vt100 fixture must have a connection_type set"
    assert group.valid?,
           "A group with connection_type set must be valid: #{group.errors.full_messages}"
  end

  # -------------------------------------------------------------------------
  # owner_group_id — auto-assign and uniqueness (Session 38)
  # -------------------------------------------------------------------------

  test "owner_group_id auto-assigns to 1 on create when owner has no existing groups" do
    # charlie (owners(:three)) has no connection_groups in the fixtures, so the
    # first group created for charlie should receive owner_group_id: 1.
    # We trigger validation (which fires the before_validation callback) without
    # requiring a full save — owner_group_id must be set regardless of other errors.
    group = ConnectionGroup.new(owner: owners(:three))
    group.valid?  # fires before_validation; minimum_two_members will also fail — that's fine
    assert_equal 1, group.owner_group_id,
                 "Auto-assign must set owner_group_id to 1 when the owner has no existing groups"
  end

  test "owner_group_id auto-assigns as max+1 when owner already has groups" do
    # alice already has alice_pdp11_vax with owner_group_id: 1.
    # Creating a second group for alice must auto-assign owner_group_id: 2.
    # alice_pdp11 and alice_vax may appear in multiple groups (uniqueness is
    # per group, not global), so using them here does not conflict with the fixture.
    new_group = ConnectionGroup.create!(
      owner: owners(:one),
      connection_members: [
        ConnectionMember.new(computer: computers(:alice_pdp11)),
        ConnectionMember.new(computer: computers(:alice_vax))
      ]
    )
    assert_equal 2, new_group.owner_group_id,
                 "Auto-assign must set owner_group_id to max(existing)+1 for alice's second group"
  end

  test "owner_group_id uniqueness is scoped to owner — different owners may share the same value" do
    # Both fixture groups have owner_group_id: 1, but for different owners.
    # The UNIQUE INDEX is (owner_id, owner_group_id), so this is valid.
    group_alice = connection_groups(:alice_pdp11_vax)
    group_bob   = connection_groups(:bob_pdp8_vt100)
    assert_equal 1, group_alice.owner_group_id
    assert_equal 1, group_bob.owner_group_id
    assert group_alice.valid?,
           "alice's group with owner_group_id 1 must be valid: #{group_alice.errors.full_messages}"
    assert group_bob.valid?,
           "bob's group with owner_group_id 1 must also be valid — the constraint is per owner: #{group_bob.errors.full_messages}"
  end

  # -------------------------------------------------------------------------
  # label validation — max 100 characters (Session 38)
  # -------------------------------------------------------------------------

  test "invalid when label exceeds 100 characters" do
    group = connection_groups(:bob_pdp8_vt100)
    group.label = "x" * 101
    assert_not group.valid?,
               "A label longer than 100 characters must make the group invalid"
    assert group.errors[:label].any?,
           "Validation error must be reported on :label for an over-length value"
  end

  test "valid when label is exactly 100 characters" do
    # Boundary: 100 is the allowed maximum
    group = connection_groups(:bob_pdp8_vt100)
    group.label = "x" * 100
    assert group.valid?,
           "A label of exactly 100 characters must be valid: #{group.errors.full_messages}"
  end

  # -------------------------------------------------------------------------
  # Associations — belongs_to
  # -------------------------------------------------------------------------

  test "belongs to owner" do
    group = connection_groups(:bob_pdp8_vt100)
    assert_respond_to group, :owner
    assert_equal owners(:two), group.owner,
                 "bob_pdp8_vt100 must belong to owner two (bob)"
  end

  test "belongs to connection_type (optional)" do
    group = connection_groups(:bob_pdp8_vt100)
    assert_respond_to group, :connection_type
    assert_instance_of ConnectionType, group.connection_type
    assert_equal connection_types(:rs232), group.connection_type
  end

  # -------------------------------------------------------------------------
  # Associations — has_many
  # -------------------------------------------------------------------------

  test "has_many connection_members" do
    group = connection_groups(:bob_pdp8_vt100)
    assert_respond_to group, :connection_members
    assert group.connection_members.any?,
           "bob_pdp8_vt100 must have at least one member for this test to be meaningful"
  end

  test "has_many computers through connection_members" do
    group = connection_groups(:bob_pdp8_vt100)
    assert_respond_to group, :computers
    computer_ids = group.computers.pluck(:id)
    assert_includes computer_ids, computers(:bob_pdp8).id,
                    "bob_pdp8 must appear in bob_pdp8_vt100 group's computers"
    assert_includes computer_ids, computers(:bob_vt100).id,
                    "bob_vt100 must appear in bob_pdp8_vt100 group's computers"
  end

  # -------------------------------------------------------------------------
  # Cascade: dependent: :delete_all — members are deleted when group is destroyed
  # -------------------------------------------------------------------------

  test "destroying group removes all its connection_members from the database" do
    # delete_all skips Ruby callbacks on members — the SQL DELETE is issued directly
    group = connection_groups(:alice_pdp11_vax)
    member_ids = group.connection_members.pluck(:id)
    assert member_ids.any?,
           "alice_pdp11_vax must have members for this cascade test to be meaningful"

    group.destroy
    surviving = ConnectionMember.where(id: member_ids).count
    assert_equal 0, surviving,
                 "All connection_members must be deleted (delete_all) when the group is destroyed"
  end

  test "destroying group does not destroy the computers themselves" do
    # delete_all only removes join rows; source computers must remain intact
    group = connection_groups(:alice_pdp11_vax)
    computer_ids = group.computers.pluck(:id)
    assert computer_ids.any?

    group.destroy
    surviving = Computer.where(id: computer_ids).count
    assert_equal computer_ids.size, surviving,
                 "Computers must not be destroyed when their group is destroyed"
  end
end
