# decor/test/controllers/storage_locations_controller_test.rb
# version 1.0
# Session B (Storage Locations feature, Part 2 of 6).
#
# StorageLocationsController access model (fully private — different from
# SoftwareItemsController, which has a public index/show):
#   index/new/create/edit/update/destroy/delete_confirm — ALL require login
#   AND are scoped to Current.owner. There is no action any of these tests
#   exercise while logged out that returns 200 — every one must redirect.
#
# Fixtures used:
#   storage_locations(:alice_attic) — owner one (alice), name "Attic Shelf 3"
#   storage_locations(:bob_garage)  — owner two (bob),   name "Garage Box B"
#   owners(:one) — alice
#   owners(:two) — bob
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
