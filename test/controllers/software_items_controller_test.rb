# decor/test/controllers/software_items_controller_test.rb
# version 1.1
# v1.1 (Session 46): Software feature Session D — CRUD controller tests.
#   Added tests for new, create, edit, update, destroy.
#   Covers: success paths, validation failures, login guard, ownership guard.
# v1.0 (Session 45): Software feature Session C — read-only show tests.
#
# SoftwareItemsController access model:
#   show              — publicly accessible (no login required)
#   new / create      — require_login; scoped to Current.owner
#   edit / update     — require_login + must own the record
#   destroy           — require_login + must own the record
#
# Fixtures used:
#   software_items(:alice_vms)       — owner one (alice), installed on alice_pdp11,
#                                      has name/condition/version — richest fixture.
#   software_items(:alice_rt11_spare) — owner one (alice), no computer (unattached).
#   software_items(:bob_rsts)        — owner two (bob), no condition/version.
#   software_names(:vms)             — used as :software_name_id in valid create params.
#   software_names(:tops20)          — used as :software_name_id in valid update params.
#   owners(:one)                     — alice; used as the record owner.
#   owners(:two)                     — bob; used as a different owner for auth tests.

require "test_helper"

class SoftwareItemsControllerTest < ActionDispatch::IntegrationTest
  # ═══════════════════════════════════════════════════════════════════════════
  # show
  # ═══════════════════════════════════════════════════════════════════════════

  test "show returns 200 for a fully populated item when logged in as owner" do
    item = software_items(:alice_vms)
    login_as owners(:one)

    get software_item_url(item)

    assert_response :success
  end

  test "show returns 200 for an unattached item when logged in as owner" do
    item = software_items(:alice_rt11_spare)
    login_as owners(:one)

    get software_item_url(item)

    assert_response :success
  end

  test "show returns 200 for an item with optional fields absent" do
    item = software_items(:bob_rsts)
    login_as owners(:two)

    get software_item_url(item)

    assert_response :success
  end

  test "show returns 200 when a different logged-in owner views the item" do
    item = software_items(:alice_vms)
    login_as owners(:two)

    get software_item_url(item)

    assert_response :success
  end

  test "show returns 200 when not authenticated" do
    item = software_items(:alice_vms)

    get software_item_url(item)

    assert_response :success
  end

  # ═══════════════════════════════════════════════════════════════════════════
  # new
  # ═══════════════════════════════════════════════════════════════════════════

  test "new returns 200 when logged in" do
    login_as owners(:one)

    get new_software_item_url

    assert_response :success
  end

  test "new redirects when not logged in" do
    # require_login guard — unauthenticated visitors cannot access the new form.
    get new_software_item_url

    assert_response :redirect
  end

  # ═══════════════════════════════════════════════════════════════════════════
  # create
  # ═══════════════════════════════════════════════════════════════════════════

  test "create with valid params redirects to show and creates a record" do
    login_as owners(:one)

    assert_difference("SoftwareItem.count", 1) do
      post software_items_url, params: {
        software_item: {
          software_name_id:      software_names(:tops20).id,
          version:               "V6.0",
          barter_status:         "no_barter"
        }
      }
    end

    assert_redirected_to software_item_url(SoftwareItem.last)
  end

  test "create with add_another redirects to new form" do
    login_as owners(:one)

    assert_difference("SoftwareItem.count", 1) do
      post software_items_url, params: {
        add_another: "1",
        software_item: {
          software_name_id: software_names(:tops20).id,
          barter_status:    "offered"
        }
      }
    end

    assert_redirected_to new_software_item_url
  end

  test "create with invalid params renders new with 422" do
    # Omitting software_name_id fails the belongs_to presence validation.
    login_as owners(:one)

    assert_no_difference("SoftwareItem.count") do
      post software_items_url, params: {
        software_item: {
          software_name_id: "",
          barter_status:    "no_barter"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "create redirects when not logged in" do
    assert_no_difference("SoftwareItem.count") do
      post software_items_url, params: {
        software_item: {
          software_name_id: software_names(:vms).id,
          barter_status:    "no_barter"
        }
      }
    end

    assert_response :redirect
  end

  # ═══════════════════════════════════════════════════════════════════════════
  # edit
  # ═══════════════════════════════════════════════════════════════════════════

  test "edit returns 200 when logged in as owner" do
    item = software_items(:alice_vms)
    login_as owners(:one)

    get edit_software_item_url(item)

    assert_response :success
  end

  test "edit redirects when not logged in" do
    item = software_items(:alice_vms)

    get edit_software_item_url(item)

    assert_response :redirect
  end

  test "edit redirects when logged in as a different owner" do
    # bob cannot edit alice's software item.
    item = software_items(:alice_vms)
    login_as owners(:two)

    get edit_software_item_url(item)

    assert_response :redirect
  end

  # ═══════════════════════════════════════════════════════════════════════════
  # update
  # ═══════════════════════════════════════════════════════════════════════════

  test "update with valid params redirects to show" do
    item = software_items(:alice_vms)
    login_as owners(:one)

    patch software_item_url(item), params: {
      software_item: {
        software_name_id: software_names(:tops20).id,
        version:          "V7.0",
        barter_status:    "offered"
      }
    }

    assert_redirected_to software_item_url(item)
  end

  test "update with invalid params renders edit with 422" do
    item = software_items(:alice_vms)
    login_as owners(:one)

    patch software_item_url(item), params: {
      software_item: { software_name_id: "" }
    }

    assert_response :unprocessable_entity
  end

  test "update redirects when not logged in" do
    item = software_items(:alice_vms)

    patch software_item_url(item), params: {
      software_item: { version: "V7.0" }
    }

    assert_response :redirect
  end

  test "update redirects when logged in as a different owner" do
    item = software_items(:alice_vms)
    login_as owners(:two)

    patch software_item_url(item), params: {
      software_item: { version: "V7.0" }
    }

    assert_response :redirect
  end

  # ═══════════════════════════════════════════════════════════════════════════
  # destroy
  # ═══════════════════════════════════════════════════════════════════════════

  test "destroy deletes the record and redirects to owner's software sub-page" do
    item   = software_items(:alice_vms)
    owner  = owners(:one)
    login_as owner

    assert_difference("SoftwareItem.count", -1) do
      delete software_item_url(item)
    end

    assert_redirected_to software_owner_url(owner)
  end

  test "destroy redirects when not logged in" do
    item = software_items(:alice_vms)

    assert_no_difference("SoftwareItem.count") do
      delete software_item_url(item)
    end

    assert_response :redirect
  end

  test "destroy redirects when logged in as a different owner" do
    item = software_items(:alice_vms)
    login_as owners(:two)

    assert_no_difference("SoftwareItem.count") do
      delete software_item_url(item)
    end

    assert_response :redirect
  end
end
