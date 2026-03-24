# decor/test/models/connection_member_test.rb
# version 1.1
# v1.1 (Session 39): Added three tests for Session 38 additions:
#   - owner_member_id auto-assigns on create for a single new member added to
#     a persisted group (straightforward DB max+1 case)
#   - owner_member_id auto-assigns with in-memory siblings (new group created with
#     2+ members at once — no persisted siblings to query, so callback must scan
#     the parent's in-memory connection_members collection)
#   - label over 100 characters is invalid
# v1.0 (Session 32): Initial model tests for ConnectionMember.
#
# Coverage:
#   - computer_id uniqueness scoped to connection_group_id
#     (same computer in same group → invalid; same computer in different group → valid)
#   - belongs_to :connection_group, :computer associations
#   - owner_member_id auto-assign — persisted group (DB max) and new group (in-memory scan)
#   - label max 100 characters
#   - after_destroy :cleanup_undersized_group:
#     (a) 2-member group loses 1 member → count drops to 1 → group auto-destroys
#     (b) 3-member group loses 1 member → count stays at 2 → group survives
#
# Fixtures:
#   connection_members(:bob_pdp8_member)    — computer: bob_pdp8,   group: bob_pdp8_vt100, owner_member_id: 1
#   connection_members(:bob_vt100_member)   — computer: bob_vt100,  group: bob_pdp8_vt100, owner_member_id: 2
#   connection_members(:alice_pdp11_member) — computer: alice_pdp11, group: alice_pdp11_vax, owner_member_id: 1
#   connection_members(:alice_vax_member)   — computer: alice_vax,   group: alice_pdp11_vax, owner_member_id: 2
#
# Both fixture groups have exactly 2 members, making them ideal for testing
# the auto-destroy boundary. The 3-member test creates its own group inline
# using alice's three computers (alice_pdp11, alice_vax, unassigned_condition_test).

require "test_helper"

class ConnectionMemberTest < ActiveSupport::TestCase
  # -------------------------------------------------------------------------
  # Associations
  # -------------------------------------------------------------------------

  test "belongs to connection_group" do
    member = connection_members(:bob_pdp8_member)
    assert_respond_to member, :connection_group
    assert_equal connection_groups(:bob_pdp8_vt100), member.connection_group
  end

  test "belongs to computer" do
    member = connection_members(:bob_pdp8_member)
    assert_respond_to member, :computer
    assert_equal computers(:bob_pdp8), member.computer
  end

  # -------------------------------------------------------------------------
  # Uniqueness: computer_id scoped to connection_group_id
  # -------------------------------------------------------------------------

  test "invalid when the same computer appears twice in the same group" do
    # bob_pdp8 is already in bob_pdp8_vt100 via the bob_pdp8_member fixture
    duplicate = ConnectionMember.new(
      connection_group: connection_groups(:bob_pdp8_vt100),
      computer: computers(:bob_pdp8)
    )
    assert_not duplicate.valid?,
               "Adding the same computer to the same group a second time must be invalid"
    assert duplicate.errors[:computer_id].any?,
           "Uniqueness violation must be reported on :computer_id"
  end

  test "valid when the same computer appears in a different group" do
    # Uniqueness is scoped per group — the same device may be in multiple groups.
    # bob_pdp8 is in bob_pdp8_vt100; adding it to alice_pdp11_vax uses a different
    # connection_group_id, so the uniqueness constraint must not fire.
    # (Cross-owner integrity is enforced at the ConnectionGroup level, not here.)
    member = ConnectionMember.new(
      connection_group: connection_groups(:alice_pdp11_vax),
      computer: computers(:bob_pdp8)  # already in bob_pdp8_vt100, but not in this group
    )
    assert member.valid?,
           "Same computer in a different group must be valid at the member level: #{member.errors.full_messages}"
  end

  # -------------------------------------------------------------------------
  # owner_member_id — auto-assign (Session 38)
  # -------------------------------------------------------------------------

  test "owner_member_id auto-assigns on create for a single new member added to a persisted group" do
    # Create a 2-member group for alice first. Both members persist with
    # owner_member_ids 1 and 2 (assigned in creation order). Then add a third
    # member — the callback reads the DB max (2) and assigns 3.
    # alice's computers (alice_pdp11, alice_vax) may be in multiple groups;
    # the UNIQUE index is (connection_group_id, computer_id), not global.
    group = ConnectionGroup.create!(
      owner: owners(:one),
      connection_members: [
        ConnectionMember.new(computer: computers(:alice_pdp11)),
        ConnectionMember.new(computer: computers(:alice_vax))
      ]
    )
    # unassigned_condition_test belongs to alice (owners(:one)) and is not
    # in any fixture group, making it a safe choice for the new member.
    new_member = group.connection_members.create!(
      computer: computers(:unassigned_condition_test)
    )
    assert_equal 3, new_member.owner_member_id,
                 "Third member added to a persisted group must receive owner_member_id 3 (max 2 + 1)"
  end

  test "owner_member_id auto-assigns correctly when a new group is created with multiple members at once" do
    # When a new group is created via nested attributes (or ConnectionGroup.create!
    # with a connection_members: array), all members are in-memory simultaneously —
    # there are no persisted siblings yet. The callback must scan the parent's
    # in-memory connection_members collection (using the data-owner-member-id
    # attribute pattern from the Stimulus controller on the form side).
    # On the model side, the before_create callback iterates sibling records
    # to find the current max and assigns max+1.
    group = ConnectionGroup.create!(
      owner: owners(:one),
      connection_members: [
        ConnectionMember.new(computer: computers(:alice_pdp11)),
        ConnectionMember.new(computer: computers(:alice_vax))
      ]
    )
    member_ids = group.connection_members.order(:owner_member_id).pluck(:owner_member_id)
    assert_equal [1, 2], member_ids,
                 "Members created together in one group must receive sequential owner_member_ids [1, 2]"
  end

  # -------------------------------------------------------------------------
  # label validation — max 100 characters (Session 38)
  # -------------------------------------------------------------------------

  test "invalid when label exceeds 100 characters" do
    member = connection_members(:bob_pdp8_member)
    member.label = "x" * 101
    assert_not member.valid?,
               "A label longer than 100 characters must make the member invalid"
    assert member.errors[:label].any?,
           "Validation error must be reported on :label for an over-length value"
  end

  test "valid when label is exactly 100 characters" do
    # Boundary: 100 is the allowed maximum — must pass
    member = connection_members(:bob_pdp8_member)
    member.label = "x" * 100
    assert member.valid?,
           "A label of exactly 100 characters must be valid: #{member.errors.full_messages}"
  end

  test "valid when label is nil" do
    # label is optional — nil must be accepted
    member = connection_members(:bob_pdp8_member)
    member.label = nil
    assert member.valid?,
           "A nil label must be valid (label is optional): #{member.errors.full_messages}"
  end

  # -------------------------------------------------------------------------
  # after_destroy :cleanup_undersized_group
  # (a) 2-member group: removing 1 → count becomes 1 → group auto-destroys
  # -------------------------------------------------------------------------

  test "auto-destroys parent group when member count falls below 2 (2→1)" do
    # bob_pdp8_vt100 has exactly 2 members. Destroying one drops the count to 1.
    # The after_destroy callback checks group.connection_members.count < 2
    # and calls group.destroy to clean up the now-undersized group.
    group = connection_groups(:bob_pdp8_vt100)
    group_id = group.id

    connection_members(:bob_pdp8_member).destroy

    assert_not ConnectionGroup.exists?(group_id),
               "Group must be auto-destroyed after member count drops from 2 to 1"
  end

  test "auto-destroys parent group when the second of a two-member group is removed" do
    # Alternate path: destroy alice_pdp11_member from alice_pdp11_vax.
    # After first removal (2→1) the after_destroy callback fires and destroys
    # the group; the second member (alice_vax_member) is deleted by delete_all
    # inside the group destroy — we never need to destroy it separately.
    group = connection_groups(:alice_pdp11_vax)
    group_id = group.id

    connection_members(:alice_pdp11_member).destroy

    assert_not ConnectionGroup.exists?(group_id),
               "Group must be auto-destroyed after the first member is removed from a 2-member group"
  end

  # -------------------------------------------------------------------------
  # after_destroy :cleanup_undersized_group
  # (b) 3-member group: removing 1 → count stays at 2 → group must survive
  # -------------------------------------------------------------------------

  test "does not destroy parent group when count drops from 3 to 2" do
    # Alice has three computers that can form a 3-member group:
    #   alice_pdp11, alice_vax, unassigned_condition_test (all owner: one)
    # We create the group inline, destroy one member, and verify the group survives.
    group = ConnectionGroup.create!(
      owner: owners(:one),
      connection_members: [
        ConnectionMember.new(computer: computers(:alice_pdp11)),
        ConnectionMember.new(computer: computers(:alice_vax)),
        ConnectionMember.new(computer: computers(:unassigned_condition_test))
      ]
    )
    group_id = group.id
    assert_equal 3, group.connection_members.count,
                 "Test setup: group must have 3 members before removal"

    # Remove one member — count drops to 2, which is >= 2, so no auto-destroy
    group.connection_members.first.destroy

    assert ConnectionGroup.exists?(group_id),
           "Group must NOT be auto-destroyed when member count drops from 3 to 2"
    assert_equal 2, ConnectionGroup.find(group_id).connection_members.count,
                 "Group must have exactly 2 members remaining after the removal"
  end
end
