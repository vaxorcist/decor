# decor/test/controllers/components_controller_test.rb - version 1.4
# v1.4 (Session 88, Storage Locations feature Session E — see
#   DECOR_PROJECT.md "Storage Locations Feature — Session Plan"): Added 3
#   tests for the new storage_location_id filter, mirroring
#   computers_controller_test.rb v1.13 exactly (happy path, the
#   ownership-guard defensive check, and the logged-out skip).
#   Learning applied directly from that file's own v1.13 fix: these tests
#   reference the EXISTING fixtures (storage_locations(:alice_attic),
#   storage_locations(:bob_garage) — both in test/fixtures/storage_locations.yml
#   v1.0) rather than calling StorageLocation.create!, avoiding the
#   (owner_id, name) uniqueness collision that bug caused there.
#   Test fixtures chosen to avoid a barter-status confound: pdp11_memory and
#   pdp11_cpu are both owner one (alice) with barter_status: 0 (no_barter,
#   the default/unset value), so the default "0+1" barter filter does not
#   exclude either of them — the storage_location_id filter is the only
#   thing distinguishing which one appears in each test. (spare_disk, also
#   owner one, was NOT used for this purpose — its barter_status: 2 (wanted)
#   would be excluded by the default barter filter regardless of storage
#   location, which would confound the assertions.)
#   Component fixtures have no serial_number values distinct enough to
#   match on (all "-" per components.yml v1.5's Owner Part Number defaults)
#   — matched on description substrings instead, following this file's own
#   v1.3 established pattern ("256KB" for pdp11_memory). "KD11-A" (from
#   pdp11_cpu's description "KD11-A CPU board") is introduced in this
#   version as a second unique substring.
#
# v1.3 (Session 22): Fixed 5 barter filter test errors — component fixtures have
#   no serial_number, so assert_includes response.body, component.serial_number
#   was passing nil and raising TypeError. Switched to description substrings
#   that are unique within the fixture set:
#     pdp11_memory           → "256KB"  (from "Original 256KB core memory board")
#     spare_disk             → "RL02"   (from "RL02 disk drive, spare…")
#     charlie_vt100_terminal → "VT100"  (from "VT100 terminal connected to…")
#
# v1.2 (Session 22): Added barter_status filter tests (5 tests).
# v1.1 (Session 12): Added "destroy with source=computer_show redirects to computer show page"
#   Covers the new source=computer_show branch added in components_controller v1.5
#   (deletion from computers/show stays on the computer show page).
#
# Fixture notes:
#   owners(:one)                    = alice (admin)
#   owners(:two)                    = bob
#   components(:pdp11_cpu)          = KD11-A CPU board, owner: alice, computer: alice_pdp11, barter_status: 0 (no_barter)
#   components(:pdp11_memory)       = 256KB memory board, owner: alice, computer: alice_pdp11, barter_status: 0 (no_barter)
#   components(:spare_disk)         = RL02 spare disk,   owner: alice, computer: nil,  barter_status: 2 (wanted)
#   components(:charlie_vt100_terminal) = VT100 terminal, owner: charlie,              barter_status: 1 (offered)
#   computers(:alice_pdp11)         = alice's PDP-11/70 — redirect target for computer_show test
#   storage_locations(:alice_attic) = owner: one (alice), name: "Attic Shelf 3"
#   storage_locations(:bob_garage)  = owner: two (bob),   name: "Garage Box B"
#   Each test runs in a rolled-back transaction.

require "test_helper"

class ComponentsControllerTest < ActionDispatch::IntegrationTest
  # ---------------------------------------------------------------------------
  # Destroy — source param redirect behaviour
  # ---------------------------------------------------------------------------

  test "destroy with source=owner redirects to owner page" do
    # When a component is deleted from the owner's show page, the user should
    # be returned to that owner's page, not the components index.
    login_as owners(:one) # alice
    assert_difference "Component.count", -1 do
      delete component_url(components(:pdp11_cpu)), params: { source: "owner" }
    end
    assert_redirected_to owner_path(owners(:one))
    assert_equal "Component was successfully deleted.", flash[:notice]
  end

  test "destroy with source=computer_show redirects to computer show page" do
    # When a component is deleted from the computer show page, the user should
    # stay on that computer's show page (not be sent to the edit page or index).
    login_as owners(:one) # alice
    assert_difference "Component.count", -1 do
      delete component_url(components(:pdp11_cpu)), params: { source: "computer_show" }
    end
    assert_redirected_to computer_path(computers(:alice_pdp11))
    assert_equal "Component was successfully deleted.", flash[:notice]
  end

  test "destroy with source=computer redirects to computer edit page" do
    # Regression guard: the pre-existing source=computer behaviour (added before
    # Session 11) must not have been broken by the new branches.
    # Deleting a component from the computer edit page returns the user there.
    login_as owners(:one) # alice
    assert_difference "Component.count", -1 do
      delete component_url(components(:pdp11_cpu)), params: { source: "computer" }
    end
    assert_redirected_to edit_computer_path(computers(:alice_pdp11))
    assert_equal "Component was successfully deleted.", flash[:notice]
  end

  test "destroy without source redirects to components index" do
    # Default behaviour (no source param): redirect to the components index.
    login_as owners(:one) # alice
    assert_difference "Component.count", -1 do
      delete component_url(components(:pdp11_cpu))
    end
    assert_redirected_to components_path
    assert_equal "Component was successfully deleted.", flash[:notice]
  end

  # ---------------------------------------------------------------------------
  # Barter filter — logged-in users see filtered results; logged-out see all
  # ---------------------------------------------------------------------------
  #
  # Component fixtures have no serial_number, so we match on description substrings
  # that are unique within the fixture set:
  #   "256KB"  → pdp11_memory (no_barter)
  #   "RL02"   → spare_disk   (wanted)
  #   "VT100"  → charlie_vt100_terminal (offered)
  #
  # Default filter for logged-in users: "0+1" (no_barter + offered).
  # spare_disk (wanted) must be hidden; pdp11_memory (no_barter) must be visible.

  test "logged-in index default barter filter hides wanted components" do
    # No barter_status param → controller uses default "0+1" (no_barter + offered).
    # spare_disk has barter_status: wanted (2) → must be excluded.
    login_as owners(:one)
    get components_path
    assert_response :success
    assert_includes     response.body, "256KB",
      "pdp11_memory (no_barter) should be visible under the default 0+1 filter"
    assert_not_includes response.body, "RL02",
      "spare_disk (wanted) should be hidden under the default 0+1 filter"
  end

  test "logged-in index barter_status=2 shows only wanted components" do
    # Explicitly requesting wanted (2) → spare_disk visible, pdp11_memory hidden.
    login_as owners(:one)
    get components_path(barter_status: "2")
    assert_response :success
    assert_includes     response.body, "RL02",
      "spare_disk (wanted) should be visible when filtering by barter_status=2"
    assert_not_includes response.body, "256KB",
      "pdp11_memory (no_barter) should be hidden when filtering by barter_status=2"
  end

  test "logged-in index barter_status=1 shows only offered components" do
    # Filtering by offered (1) → charlie_vt100_terminal visible, spare_disk hidden.
    login_as owners(:one)
    get components_path(barter_status: "1")
    assert_response :success
    assert_includes     response.body, "VT100",
      "charlie_vt100_terminal (offered) should be visible when filtering by barter_status=1"
    assert_not_includes response.body, "RL02",
      "spare_disk (wanted) should be hidden when filtering by barter_status=1"
  end

  test "logged-in index barter_status=0 shows only no_barter components" do
    # Filtering by no_barter only → pdp11_memory visible, spare_disk hidden.
    login_as owners(:one)
    get components_path(barter_status: "0")
    assert_response :success
    assert_includes     response.body, "256KB",
      "pdp11_memory (no_barter) should be visible when filtering by barter_status=0"
    assert_not_includes response.body, "RL02",
      "spare_disk (wanted) should be hidden when filtering by barter_status=0"
  end

  test "logged-out index shows all components regardless of barter_status" do
    # Non-logged-in visitors: no barter filter applied.
    # Both pdp11_memory (no_barter) and spare_disk (wanted) must be visible.
    get components_path
    assert_response :success
    assert_includes response.body, "256KB",
      "pdp11_memory should be visible to logged-out visitors (no filter)"
    assert_includes response.body, "RL02",
      "spare_disk (wanted) should be visible to logged-out visitors (no filter)"
  end

  # ---------------------------------------------------------------------------
  # Storage Location filter — Session E (Storage Locations feature)
  # ---------------------------------------------------------------------------
  #
  # Storage locations are private per-owner data (see DECOR_PROJECT.md "Storage
  # Locations Feature — Session Plan," Session D privacy audit — passed with no
  # code changes needed). The filter dropdown only ever offers Current.owner's
  # own storage locations (ComponentsHelper#component_filter_storage_locations_options),
  # so a legitimate request can never submit another owner's id — these tests
  # cover both the happy path and the defensive ownership check in the
  # controller (ComponentsController#index v2.3) for a crafted/invalid param.
  #
  # pdp11_memory and pdp11_cpu are both owner one (alice) with barter_status: 0
  # (no_barter) — chosen deliberately so the default "0+1" barter filter does
  # not exclude either of them, leaving storage_location_id as the only
  # distinguishing filter in these assertions.

  test "logged-in index filtered by storage_location_id shows only components in that location" do
    alice_location = storage_locations(:alice_attic)
    components(:pdp11_memory).update_column(:storage_location_id, alice_location.id)
    # pdp11_cpu is left with no storage_location_id (nil) — must be excluded.

    login_as owners(:one)
    get components_path(storage_location_id: alice_location.id)
    assert_response :success
    assert_includes     response.body, "256KB",
      "pdp11_memory should be visible when filtering by its own storage_location_id"
    assert_not_includes response.body, "KD11-A",
      "pdp11_cpu (no storage_location_id) should be hidden by the storage_location_id filter"
  end

  test "storage_location_id filter is ignored when it belongs to a different owner" do
    # bob's own storage location — alice must not be able to filter by it,
    # even though nothing stops her from typing its id directly into the URL.
    bob_location = storage_locations(:bob_garage)

    login_as owners(:one)
    get components_path(storage_location_id: bob_location.id)
    assert_response :success
    # The invalid filter must be silently ignored — the default barter filter
    # (0+1) still applies on top, so pdp11_memory (no_barter) remains visible,
    # exactly as it is with no storage_location_id param at all.
    assert_includes response.body, "256KB",
      "pdp11_memory should still be visible — an unowned storage_location_id must be ignored, not applied"
  end

  test "logged-out index ignores storage_location_id param entirely" do
    alice_location = storage_locations(:alice_attic)
    components(:pdp11_memory).update_column(:storage_location_id, alice_location.id)

    get components_path(storage_location_id: alice_location.id)
    assert_response :success
    # No login → the entire storage_location_id block is skipped (guarded by
    # `if logged_in?`), same as the barter_status filter above. Both
    # pdp11_memory and pdp11_cpu must be visible.
    assert_includes response.body, "256KB",
      "pdp11_memory should be visible to logged-out visitors regardless of storage_location_id"
    assert_includes response.body, "KD11-A",
      "pdp11_cpu should be visible to logged-out visitors regardless of storage_location_id"
  end
end
