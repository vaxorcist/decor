# decor/test/models/connection_type_test.rb
# version 1.0
# Session 32 (Part 1b): Model tests for ConnectionType.
#
# Coverage:
#   - name presence validation (required)
#   - name uniqueness validation
#   - label is optional (nullable column)
#   - has_many :connection_groups association exists
#   - dependent: :restrict_with_error blocks destroy when groups are attached
#   - destroy succeeds when no groups are attached
#
# Fixtures used:
#   connection_types(:rs232)    — name "RS-232 Serial"; used by bob_pdp8_vt100 group → blocked
#   connection_types(:ethernet) — name "Ethernet"; no groups attached → can be destroyed

require "test_helper"

class ConnectionTypeTest < ActiveSupport::TestCase
  # -------------------------------------------------------------------------
  # Presence validation — name is required
  # -------------------------------------------------------------------------

  test "valid with name and label" do
    ct = ConnectionType.new(name: "USB", label: "USB 2.0 peripheral connection")
    assert ct.valid?, "ConnectionType with name and label must be valid: #{ct.errors.full_messages}"
  end

  test "valid with name and no label" do
    # label column is nullable — omitting it must not cause a validation error
    ct = ConnectionType.new(name: "USB")
    assert ct.valid?, "ConnectionType with name only must be valid: #{ct.errors.full_messages}"
  end

  test "invalid without name" do
    ct = ConnectionType.new(label: "A label with no name")
    assert_not ct.valid?
    assert_includes ct.errors[:name], "can't be blank"
  end

  # -------------------------------------------------------------------------
  # Uniqueness validation — name must be unique across all connection types
  # -------------------------------------------------------------------------

  test "invalid with a duplicate name" do
    # rs232 fixture already owns the name "RS-232 Serial"
    duplicate = ConnectionType.new(name: "RS-232 Serial")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "valid with a name not yet used" do
    ct = ConnectionType.new(name: "FireWire 400")
    assert ct.valid?, "A brand-new name must be valid: #{ct.errors.full_messages}"
  end

  # -------------------------------------------------------------------------
  # Association — has_many :connection_groups
  # -------------------------------------------------------------------------

  test "responds to connection_groups" do
    ct = connection_types(:rs232)
    assert_respond_to ct, :connection_groups
  end

  test "rs232 fixture has at least one connection_group" do
    # Confirms that the fixture data supports the restrict_with_error tests below
    ct = connection_types(:rs232)
    assert ct.connection_groups.any?,
           "rs232 must have at least one group for the restrict_with_error tests to be meaningful"
  end

  # -------------------------------------------------------------------------
  # dependent: :restrict_with_error — destroy blocked when groups exist
  # -------------------------------------------------------------------------

  test "cannot be destroyed when connection_groups are attached" do
    # rs232 is referenced by the bob_pdp8_vt100 group fixture — destroy must fail
    ct = connection_types(:rs232)
    result = ct.destroy
    assert_not result,
               "destroy must return false when groups reference this connection type"
    assert ct.errors[:base].any?,
           "A :base error must be added so the caller can surface a useful message"
    assert ConnectionType.exists?(ct.id),
           "rs232 must still be present in the database after a blocked destroy"
  end

  test "can be destroyed when no connection_groups are attached" do
    # ethernet has no groups in fixtures — destroy must succeed
    ct = connection_types(:ethernet)
    id = ct.id
    assert ct.destroy,
           "destroy must succeed when no groups reference this connection type"
    assert_not ConnectionType.exists?(id),
               "ethernet must be gone from the database after a successful destroy"
  end
end
