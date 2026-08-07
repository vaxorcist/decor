# decor/test/controllers/storage_locations_controller_test.rb
# version 1.2
# v1.2 (Session 92, bug fix): "show displays the Components section..."
#   crashed with `TypeError: no implicit conversion of nil into String` at
#   `assert_body_includes component.order_number`. Root cause:
#   decor/test/fixtures/components.yml v1.5 never sets `order_number` on
#   ANY component fixture (unlike computers.yml, where every fixture sets
#   it explicitly) — so components(:pdp11_memory).order_number was nil,
#   and response_helpers.rb's assert_body_includes(nil) called
#   response.body.include?(nil), which raises exactly this TypeError (the
#   nil is the argument to include?, not response.body itself). Fixed by
#   setting order_number explicitly in the test's own `update!` call,
#   alongside the owner_part_number override already there — consistent
#   with this file's stated v1.1 design of never modifying the shared
#   fixture .yml files and assigning needed fields inside each test
#   instead. No other test in this file reads component.order_number
#   without either creating its own record (Peripherals tests) or not
#   needing the value (sort/omission/isolation tests), so this was the
#   only test affected.
# v1.1 (Session 91, ad-hoc follow-up to Session 90): Added a full `show`
#   test section — the `show` action itself (added Session 90,
#   storage_locations_controller.rb v1.2) had NO tests at all until now.
#   Covers: login/ownership guards (matching every other action's pattern
#   in this file), correct field display per category (Computers/
#   Peripherals/Components/Software), correct case-insensitive alphabetical
#   sort within each category by Model/Type/Software Name (the Session 91
#   rework — see storage_locations_controller.rb v1.3's
#   build_computer_rows/build_component_rows/build_software_rows), and that
#   a category section is omitted entirely when it has no items.
#
#   No fixture (.yml) files were modified for this — per Pre-Implementation
#   Verification, computers.yml/components.yml/software_items.yml are
#   shared across multiple other test files not reviewed this session
#   (e.g. computers_controller_test.rb's own Storage Location filter
#   tests, Session 88), so permanently assigning storage_location_id to
#   existing shared fixtures risked silently breaking assumptions in files
#   not in hand. Instead, every test below assigns storage_location via
#   `update!` on existing fixtures (or creates a small number of new
#   Computer rows) INSIDE each test — Rails' transactional fixtures roll
#   this back automatically after every test, so fixture files' on-disk
#   state (storage_location_id: nil for these rows) is exactly what every
#   OTHER test file continues to see. This is the "counts on records
#   created/modified within the test itself" case PROGRAMMING_GENERAL.md's
#   "Derive Test Assertions from Data, Not Constants" explicitly allows.
#
#   Sort-order assertions derive the expected order from the fixtures'
#   actual data (computer_model/component_type/software_name .name values,
#   read from the DB) rather than hardcoding "the order should be X, Y" —
#   per the same PROGRAMMING_GENERAL.md rule. New ComputerModel records
#   (used only for the Peripherals section, since no existing fixture
#   Computer/Peripheral for alice or bob has device_type: peripheral) are
#   NOT created — the existing `vt100` and `pdp8` ComputerModel fixtures
#   (already referenced by other owners' Computer fixtures in
#   computers.yml) are reused for two new alice-owned Peripheral rows
#   instead, avoiding any new lookup-table fixture and avoiding any
#   guessed ComponentType/ComputerModel validation shape.
#
# v1.0 (Session B, Storage Locations feature, Part 2 of 6): initial CRUD
#   test coverage (index/new/create/edit/update/delete_confirm/destroy).
#   See the original v1.0 header notes below, preserved for continuity.
#
# StorageLocationsController access model (fully private — different from
# SoftwareItemsController, which has a public index/show):
#   index/new/create/edit/update/destroy/delete_confirm — ALL require login
#   AND are scoped to Current.owner. There is no action any of these tests
#   exercise while logged out that returns 200 — every one must redirect.
#   `show` (added Session 90) follows the exact same access model — no
#   admin exception, unlike computers#show which is public.
#
# Fixtures used:
#   storage_locations(:alice_attic) — owner one (alice), name "Attic Shelf 3"
#   storage_locations(:bob_garage)  — owner two (bob),   name "Garage Box B"
#   owners(:one) — alice
#   owners(:two) — bob
#   computers(:alice_pdp11)  — owner one, computer_model: pdp11_70
#   computers(:alice_vax)    — owner one, computer_model: vax11_780
#   components(:pdp11_memory) — owner one, computer: alice_pdp11, component_type: memory_board
#   components(:pdp11_cpu)     — owner one, computer: alice_pdp11, component_type: cpu_board
#   software_items(:alice_vms)        — owner one, software_name: vms
#   software_items(:alice_rt11_spare) — owner one, software_name: rt11
#   computer_models(:vt100), computer_models(:pdp8) — reused (not newly
#     created) for the two ad-hoc alice-owned Peripheral rows the `show`
#     tests below build
#
# No hardcoded count assertions across all owners' storage_locations (only
# assert_difference/assert_no_difference on the delta from a single test's
# own action) — per PROGRAMMING_GENERAL.md "Derive Test Assertions from
# Data, Not Constants".

require "test_helper"

class StorageLocationsControllerTest < ActionDispatch::IntegrationTest
  # ═══════════════════════════════════════════════════════════════════════════
  # index
  # ═══════════════════════════════════════════════════════════════════════════

  test "index redirects when not logged in" do
    get storage_locations_url

    assert_response :redirect
  end

  test "index returns 200 when logged in" do
    login_as owners(:one)

    get storage_locations_url

    assert_response :success
  end

  test "index shows only the current owner's own storage locations" do
    alice_location = storage_locations(:alice_attic)
    bob_location    = storage_locations(:bob_garage)
    login_as owners(:one)

    get storage_locations_url

    assert_body_includes alice_location.name
    refute_body_includes bob_location.name
  end

  # ═══════════════════════════════════════════════════════════════════════════
  # show
  # ═══════════════════════════════════════════════════════════════════════════

  test "show redirects when not logged in" do
    location = storage_locations(:alice_attic)

    get storage_location_url(location)

    assert_response :redirect
  end

  test "show redirects when logged in as a different owner" do
    location = storage_locations(:alice_attic)
    login_as owners(:two)

    get storage_location_url(location)

    assert_response :redirect
  end

  test "show returns 200 when logged in as owner" do
    location = storage_locations(:alice_attic)
    login_as owners(:one)

    get storage_location_url(location)

    assert_response :success
  end

  test "show displays the Computers section with Computer Model, DEC Part Number, DEC Serial Number, and Owner Part Number" do
    location = storage_locations(:alice_attic)
    computer = computers(:alice_pdp11)
    computer.update!(storage_location: location, owner_part_number: "OPN-COMPUTER-1")
    login_as owners(:one)

    get storage_location_url(location)

    assert_body_includes "Computers"
    assert_body_includes computer.computer_model.name
    assert_body_includes computer.order_number
    assert_body_includes computer.serial_number
    assert_body_includes computer.owner_part_number
  end

  test "show displays the Peripherals section with Peripheral Model, DEC Part Number, DEC Serial Number, and Owner Part Number" do
    location = storage_locations(:alice_attic)
    peripheral = Computer.create!(
      owner:             owners(:one),
      computer_model:    computer_models(:vt100),
      device_type:       :peripheral,
      serial_number:     "ALICE-PERIPH-1",
      order_number:      "ORD-ALICE-PERIPH-1",
      owner_part_number: "OPN-PERIPHERAL-1",
      storage_location:  location
    )
    login_as owners(:one)

    get storage_location_url(location)

    assert_body_includes "Peripherals"
    assert_body_includes peripheral.computer_model.name
    assert_body_includes peripheral.order_number
    assert_body_includes peripheral.serial_number
    assert_body_includes peripheral.owner_part_number
  end

  test "show displays the Components section with Component Type, DEC Part Number, DEC Serial Number, and Owner Part Number" do
    location = storage_locations(:alice_attic)
    component = components(:pdp11_memory)
    component.update!(storage_location: location, owner_part_number: "OPN-COMPONENT-1",
                       order_number: "ORD-COMPONENT-1")
    login_as owners(:one)

    get storage_location_url(location)

    assert_body_includes "Components"
    assert_body_includes component.component_type.name
    assert_body_includes component.order_number
    assert_body_includes component.serial_number
    assert_body_includes component.owner_part_number
  end

  test "show displays the Software section with Software Name and Version" do
    location = storage_locations(:alice_attic)
    software_item = software_items(:alice_vms)
    software_item.update!(storage_location: location)
    login_as owners(:one)

    get storage_location_url(location)

    assert_body_includes "Software"
    assert_body_includes software_item.software_name.name
    assert_body_includes software_item.version
  end

  test "show sorts Computers alphabetically by Computer Model name, case-insensitively" do
    location = storage_locations(:alice_attic)
    computer_a = computers(:alice_pdp11)
    computer_b = computers(:alice_vax)
    computer_a.update!(storage_location: location)
    computer_b.update!(storage_location: location)
    login_as owners(:one)

    get storage_location_url(location)

    name_a = computer_a.computer_model.name
    name_b = computer_b.computer_model.name
    expected_first, expected_second = [name_a, name_b].sort_by(&:downcase)

    assert_operator response.body.index(expected_first), :<, response.body.index(expected_second),
                     "Expected \"#{expected_first}\" to appear before \"#{expected_second}\" in the Computers section"
  end

  test "show sorts Peripherals alphabetically by Peripheral Model name, case-insensitively" do
    location = storage_locations(:alice_attic)
    peripheral_a = Computer.create!(
      owner: owners(:one), computer_model: computer_models(:vt100), device_type: :peripheral,
      serial_number: "ALICE-PERIPH-A", order_number: "ORD-ALICE-PERIPH-A",
      owner_part_number: "OPN-PERIPH-A", storage_location: location
    )
    peripheral_b = Computer.create!(
      owner: owners(:one), computer_model: computer_models(:pdp8), device_type: :peripheral,
      serial_number: "ALICE-PERIPH-B", order_number: "ORD-ALICE-PERIPH-B",
      owner_part_number: "OPN-PERIPH-B", storage_location: location
    )
    login_as owners(:one)

    get storage_location_url(location)

    name_a = peripheral_a.computer_model.name
    name_b = peripheral_b.computer_model.name
    expected_first, expected_second = [name_a, name_b].sort_by(&:downcase)

    assert_operator response.body.index(expected_first), :<, response.body.index(expected_second),
                     "Expected \"#{expected_first}\" to appear before \"#{expected_second}\" in the Peripherals section"
  end

  test "show sorts Components alphabetically by Component Type name, case-insensitively" do
    location = storage_locations(:alice_attic)
    component_a = components(:pdp11_memory)
    component_b = components(:pdp11_cpu)
    component_a.update!(storage_location: location)
    component_b.update!(storage_location: location)
    login_as owners(:one)

    get storage_location_url(location)

    name_a = component_a.component_type.name
    name_b = component_b.component_type.name
    expected_first, expected_second = [name_a, name_b].sort_by(&:downcase)

    assert_operator response.body.index(expected_first), :<, response.body.index(expected_second),
                     "Expected \"#{expected_first}\" to appear before \"#{expected_second}\" in the Components section"
  end

  test "show sorts Software alphabetically by Software Name, case-insensitively" do
    location = storage_locations(:alice_attic)
    software_a = software_items(:alice_vms)
    software_b = software_items(:alice_rt11_spare)
    software_a.update!(storage_location: location)
    software_b.update!(storage_location: location)
    login_as owners(:one)

    get storage_location_url(location)

    name_a = software_a.software_name.name
    name_b = software_b.software_name.name
    expected_first, expected_second = [name_a, name_b].sort_by(&:downcase)

    assert_operator response.body.index(expected_first), :<, response.body.index(expected_second),
                     "Expected \"#{expected_first}\" to appear before \"#{expected_second}\" in the Software section"
  end

  test "show omits a category section entirely when that category has no items" do
    # alice_attic starts with no items assigned in fixtures — only assign
    # a Computer here, leaving Peripherals/Components/Software empty.
    location = storage_locations(:alice_attic)
    computer = computers(:alice_pdp11)
    computer.update!(storage_location: location)
    login_as owners(:one)

    get storage_location_url(location)

    assert_body_includes "Computers"
    refute_body_includes "Peripherals ("
    refute_body_includes "Components ("
    refute_body_includes "Software ("
  end

  test "show does not include another owner's items" do
    alice_location = storage_locations(:alice_attic)
    bob_computer    = computers(:bob_pdp8)
    bob_computer.update!(storage_location: storage_locations(:bob_garage))
    login_as owners(:one)

    get storage_location_url(alice_location)

    refute_body_includes bob_computer.computer_model.name
  end

  # ═══════════════════════════════════════════════════════════════════════════
  # new
  # ═══════════════════════════════════════════════════════════════════════════

  test "new redirects when not logged in" do
    get new_storage_location_url

    assert_response :redirect
  end

  test "new returns 200 when logged in" do
    login_as owners(:one)

    get new_storage_location_url

    assert_response :success
  end

  # ═══════════════════════════════════════════════════════════════════════════
  # create
  # ═══════════════════════════════════════════════════════════════════════════

  test "create with valid params redirects to index and creates a record owned by Current.owner" do
    login_as owners(:one)

    assert_difference("StorageLocation.count", 1) do
      post storage_locations_url, params: {
        storage_location: { name: "Basement Shelf 1" }
      }
    end

    assert_equal owners(:one), StorageLocation.last.owner
    assert_redirected_to storage_locations_url
  end

  test "create with blank name renders new with 422" do
    login_as owners(:one)

    assert_no_difference("StorageLocation.count") do
      post storage_locations_url, params: {
        storage_location: { name: "" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "create with a name already used by the current owner renders new with 422" do
    # alice already has "Attic Shelf 3" (storage_locations(:alice_attic)) —
    # uniqueness is scoped to owner_id (storage_location.rb v1.0), so this
    # must be rejected for alice specifically, not project-wide.
    duplicate_name = storage_locations(:alice_attic).name
    login_as owners(:one)

    assert_no_difference("StorageLocation.count") do
      post storage_locations_url, params: {
        storage_location: { name: duplicate_name }
      }
    end

    assert_response :unprocessable_entity
  end

  test "create with a name matching another owner's storage location succeeds" do
    # Uniqueness is scoped to owner_id — bob using the exact name alice
    # already has must be allowed (different owner, different scope).
    alice_name = storage_locations(:alice_attic).name
    login_as owners(:two)

    assert_difference("StorageLocation.count", 1) do
      post storage_locations_url, params: {
        storage_location: { name: alice_name }
      }
    end

    assert_equal owners(:two), StorageLocation.last.owner
  end

  test "create redirects when not logged in" do
    assert_no_difference("StorageLocation.count") do
      post storage_locations_url, params: {
        storage_location: { name: "Should Not Be Created" }
      }
    end

    assert_response :redirect
  end

  # ═══════════════════════════════════════════════════════════════════════════
  # edit
  # ═══════════════════════════════════════════════════════════════════════════

  test "edit returns 200 when logged in as owner" do
    location = storage_locations(:alice_attic)
    login_as owners(:one)

    get edit_storage_location_url(location)

    assert_response :success
  end

  test "edit redirects when not logged in" do
    location = storage_locations(:alice_attic)

    get edit_storage_location_url(location)

    assert_response :redirect
  end

  test "edit redirects when logged in as a different owner" do
    location = storage_locations(:alice_attic)
    login_as owners(:two)

    get edit_storage_location_url(location)

    assert_response :redirect
  end

  # ═══════════════════════════════════════════════════════════════════════════
  # update
  # ═══════════════════════════════════════════════════════════════════════════

  test "update with valid params redirects to index" do
    location = storage_locations(:alice_attic)
    login_as owners(:one)

    patch storage_location_url(location), params: {
      storage_location: { name: "Attic Shelf 3 (Renamed)" }
    }

    assert_redirected_to storage_locations_url
    assert_equal "Attic Shelf 3 (Renamed)", location.reload.name
  end

  test "update with blank name renders edit with 422" do
    location = storage_locations(:alice_attic)
    login_as owners(:one)

    patch storage_location_url(location), params: {
      storage_location: { name: "" }
    }

    assert_response :unprocessable_entity
  end

  test "update redirects when not logged in" do
    location = storage_locations(:alice_attic)

    patch storage_location_url(location), params: {
      storage_location: { name: "Should Not Update" }
    }

    assert_response :redirect
    assert_not_equal "Should Not Update", location.reload.name
  end

  test "update redirects when logged in as a different owner" do
    location = storage_locations(:alice_attic)
    login_as owners(:two)

    patch storage_location_url(location), params: {
      storage_location: { name: "Should Not Update" }
    }

    assert_response :redirect
    assert_not_equal "Should Not Update", location.reload.name
  end

  # ═══════════════════════════════════════════════════════════════════════════
  # delete_confirm
  # ═══════════════════════════════════════════════════════════════════════════

  test "delete_confirm returns 200 when logged in as owner" do
    location = storage_locations(:alice_attic)
    login_as owners(:one)

    get delete_confirm_storage_location_url(location)

    assert_response :success
  end

  test "delete_confirm redirects when not logged in" do
    location = storage_locations(:alice_attic)

    get delete_confirm_storage_location_url(location)

    assert_response :redirect
  end

  test "delete_confirm redirects when logged in as a different owner" do
    location = storage_locations(:alice_attic)
    login_as owners(:two)

    get delete_confirm_storage_location_url(location)

    assert_response :redirect
  end

  # ═══════════════════════════════════════════════════════════════════════════
  # destroy
  # ═══════════════════════════════════════════════════════════════════════════

  test "destroy deletes the record and redirects to index" do
    location = storage_locations(:alice_attic)
    login_as owners(:one)

    assert_difference("StorageLocation.count", -1) do
      delete storage_location_url(location)
    end

    assert_redirected_to storage_locations_url
  end

  test "destroy redirects when not logged in" do
    location = storage_locations(:alice_attic)

    assert_no_difference("StorageLocation.count") do
      delete storage_location_url(location)
    end

    assert_response :redirect
  end

  test "destroy redirects when logged in as a different owner" do
    location = storage_locations(:alice_attic)
    login_as owners(:two)

    assert_no_difference("StorageLocation.count") do
      delete storage_location_url(location)
    end

    assert_response :redirect
  end
end
