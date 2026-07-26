# decor/test/models/component_test.rb
# version 1.8
# v1.8 (Session 77): Added tests for the `search` scope (component.rb v1.8)
#   — this scope had NO test coverage at all before this session. Added
#   three tests: matching by order_number (the new field added this
#   session), confirming a query that matches nothing returns empty, and
#   confirming a blank query returns all records (the scope's own
#   documented short-circuit). Kept deliberately narrow — testing every
#   pre-existing searchable field (component type, owner, computer model,
#   description) was not part of this session's change and is left as a
#   separate future addition if wanted.
# v1.7 (Session 71 — test repair, round 2): The v1.6 fix for "spare
#   component can be peripheral" used serial_number "MB-SPARE-PERIPHERAL-001"
#   (23 characters) — over Component#serial_number's 20-char max length
#   validation, so the test failed on a NEW cause (length, not uniqueness)
#   introduced by the previous fix itself. Shortened to
#   "MB-SPARE-PERIPH-001" (19 chars). All other serial_number values added
#   in v1.6 were re-audited against the 20-char limit and are within it.
# v1.6 (Session 71 — test repair): Session 70's Owner Part Number feature
#   widened Component's uniqueness scope to (owner_id, component_type_id,
#   owner_part_number, serial_number) and made both owner_part_number and
#   serial_number default to "-" via before_validation when left blank.
#   Several tests here built Component.new/.create! with the same owner+type
#   as an existing fixture (or as another record created earlier in the same
#   test) and no explicit serial_number — under the new scope, two such
#   records both collapse to the same ("-", "-") pair and collide. Fixed by
#   giving each a distinct serial_number:
#     - "valid with required attributes"        (collided with pdp11_memory)
#     - "valid with optional computer"           (collided with pdp11_memory)
#     - "valid without computer (spare component)" (collided with spare_disk)
#     - "spare component can be peripheral"      (collided with pdp11_memory)
#   "blank serial number is always valid regardless of other blank-serial
#   components" tested a premise (allow_blank: true, no uniqueness check on
#   blank) that Session 70 deliberately removed (Option B, confirmed in
#   DECOR_PROJECT.md "Component" model notes) — a second same-owner+type
#   spare with no distinguishing value is now REJECTED, not allowed. Replaced
#   with two tests that document the actual current behaviour instead.
# v1.5 (Session 28): Added serial_number uniqueness validation tests.
#   Constraint scope: (owner_id, component_type_id, serial_number).
#   - same owner + same type + duplicate serial       → invalid
#   - same owner + different type + same serial       → valid
#   - different owner + same type + same serial       → valid  ← key difference
#     from a global constraint; owners use their own replacement numbering.
#   - blank serial number → no uniqueness check (multiple allowed per owner+type)
#   - duplicate serial number produces a descriptive error message
# v1.4 (Session 22): Added barter_status enum tests.
# v1.3: Fixed: bob_vt100_terminal → charlie_vt100_terminal to match fixture rename.

require "test_helper"

class ComponentTest < ActiveSupport::TestCase
  test "valid with required attributes" do
    component = Component.new(
      owner: owners(:one),
      component_type: component_types(:memory_board),
      serial_number: "MB-REQ-ATTR-001" # avoids colliding with pdp11_memory ("-"/"-")
    )
    assert component.valid?
  end

  test "valid with optional computer" do
    component = Component.new(
      owner: owners(:one),
      computer: computers(:alice_pdp11),
      component_type: component_types(:memory_board),
      serial_number: "MB-OPT-COMPUTER-001" # avoids colliding with pdp11_memory ("-"/"-")
    )
    assert component.valid?
  end

  test "valid without computer (spare component)" do
    component = Component.new(
      owner: owners(:one),
      computer: nil,
      component_type: component_types(:disk_drive),
      description: "Spare drive",
      serial_number: "DISK-SPARE-VALID-001" # avoids colliding with spare_disk ("-"/"-")
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

  # --- serial_number uniqueness validation tests (Session 28) ---
  # Constraint scope: (owner_id, component_type_id, serial_number).

  test "valid when serial_number is unique within owner and component type" do
    component = Component.new(
      owner: owners(:one),
      component_type: component_types(:memory_board),
      serial_number: "MB-UNIQUE-001"
    )
    assert component.valid?, "A unique serial number must be valid: #{component.errors.full_messages}"
  end

  test "invalid when same owner has duplicate serial number on same component type" do
    # Create a component for alice, then attempt a second with the same
    # owner + type + serial — must be rejected.
    Component.create!(
      owner: owners(:one),
      component_type: component_types(:memory_board),
      serial_number: "MB-DUPE-001"
    )

    duplicate = Component.new(
      owner: owners(:one),         # same owner
      component_type: component_types(:memory_board),
      serial_number: "MB-DUPE-001"
    )
    assert_not duplicate.valid?,
                "Same owner + same type + same serial must be invalid"
    assert duplicate.errors[:serial_number].any?,
           "Validation error must be on serial_number"
  end

  test "different owner may use the same serial number on the same component type" do
    # Owners invent their own replacement numbering schemes; cross-owner collisions
    # are expected and valid. Alice and Bob may each have a Memory Board "MB-001".
    Component.create!(
      owner: owners(:one),         # alice
      component_type: component_types(:memory_board),
      serial_number: "MB-SHARED-001"
    )

    bob_component = Component.new(
      owner: owners(:two),         # bob — different owner, same type+serial
      component_type: component_types(:memory_board),
      serial_number: "MB-SHARED-001"
    )
    assert bob_component.valid?,
           "Different owner + same type + same serial must be valid"
  end

  test "same serial number on different component type for the same owner is valid" do
    # "MB-CROSS-001" on memory_board and "MB-CROSS-001" on cpu_board — both valid.
    Component.create!(
      owner: owners(:one),
      component_type: component_types(:memory_board),
      serial_number: "MB-CROSS-001"
    )

    different_type = Component.new(
      owner: owners(:one),
      component_type: component_types(:cpu_board),
      serial_number: "MB-CROSS-001"
    )
    assert different_type.valid?,
           "Same owner + different type + same serial must be valid"
  end

  test "second blank-serial component of same owner+type is rejected (Option B, Session 70)" do
    # Session 70's Owner Part Number feature (Option B, confirmed in
    # DECOR_PROJECT.md) removed the old allow_blank exemption: a blank
    # serial_number now defaults to "-" via before_validation, and a SECOND
    # same-owner+type spare with no distinguishing value collides on
    # ("-", "-") and is rejected. pdp11_cpu (owner one, cpu_board) is
    # already such a fixture, so a second one must be invalid.
    existing = components(:pdp11_cpu)

    second_no_serial = Component.new(
      owner: existing.owner,
      component_type: existing.component_type
      # serial_number/owner_part_number both omitted → both default to "-",
      # which pdp11_cpu already occupies for this owner+type.
    )
    assert_not second_no_serial.valid?,
               "A second same-owner+type spare with no distinguishing value must be rejected"
    assert second_no_serial.errors[:serial_number].any?,
           "Validation error must be on serial_number"
  end

  test "different owners may each have a blank-serial spare of the same component type" do
    # pdp11_memory (owner one) and pdp8_memory (owner two) are both
    # memory_board fixtures whose serial_number/owner_part_number are both
    # "-" — proving the uniqueness scope is per-owner, so two different
    # owners' blank-serial spares of the same type never collide.
    assert components(:pdp11_memory).valid?
    assert components(:pdp8_memory).valid?
  end

  test "duplicate serial number error message is descriptive" do
    Component.create!(
      owner: owners(:one),
      component_type: component_types(:cpu_board),
      serial_number: "CPU-ERR-001"
    )

    duplicate = Component.new(
      owner: owners(:one),
      component_type: component_types(:cpu_board),
      serial_number: "CPU-ERR-001"
    )
    duplicate.valid?
    assert_match "component type", duplicate.errors[:serial_number].first,
                 "Error message must mention 'component type' to help the user understand the constraint"
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
      description: "Spare terminal not yet connected",
      serial_number: "MB-SPARE-PERIPH-001" # avoids colliding with pdp11_memory ("-"/"-"); kept within the 20-char max
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

  # --- search scope tests (Session 77) ---
  # No coverage existed for this scope before this session. Kept narrow —
  # focused on the order_number addition, plus the scope's own documented
  # blank-query short-circuit. Pre-existing searchable fields (component
  # type, owner, computer model, description) are not covered here.

  test "search matches by order_number (DEC Part Number)" do
    # Distinctive order_number that appears nowhere else in this record's
    # own fields, so a match proves the order_number branch specifically —
    # not a coincidental match on component type/owner/description.
    findable = Component.create!(
      owner: owners(:one),
      component_type: component_types(:memory_board),
      order_number: "XZQ99-PARTSEARCH",
      description: "Totally unrelated text",
      serial_number: "MB-SEARCH-ORDER-001" # avoids colliding with pdp11_memory ("-"/"-")
    )

    results = Component.search("XZQ99-PARTSEARCH")
    assert_includes results, findable,
                     "search must match on order_number (DEC Part Number)"
  end

  test "search returns no results for a query matching no field" do
    Component.create!(
      owner: owners(:one),
      component_type: component_types(:memory_board),
      order_number: "XZQ99-NOMATCH",
      serial_number: "MB-SRCH-NOMATCH-01" # avoids colliding with pdp11_memory ("-"/"-"); kept within the 20-char max
    )

    results = Component.search("NoSuchStringZZZ999")
    assert_empty results,
                 "A query matching no component/owner/type/model/order_number/description must return no results"
  end

  test "search returns all records when query is blank" do
    # Derived from data, not hardcoded — see PROGRAMMING_GENERAL.md
    # "Derive Test Assertions from Data, Not Constants."
    assert_equal Component.count, Component.search("").count,
                 "A blank query must short-circuit to all records (scope's own documented behaviour)"
  end
end
