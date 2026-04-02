# decor/test/controllers/software_items_controller_test.rb
# version 1.0
# Session 45: Software feature Session C — controller tests for read-only show action.
#
# SoftwareItemsController#show is publicly accessible (no require_login guard),
# consistent with ComputersController and ComponentsController show pages.
#
# Fixtures used:
#   software_items(:alice_vms)   — has computer, software_name, condition, version,
#                                   description: the richest fixture for testing the
#                                   fully-populated show page path.
#   software_items(:alice_rt11_spare) — no computer (unattached), exercises the
#                                       "Not installed on any hardware" branch.
#   software_items(:bob_rsts)    — no condition, no version: exercises optional fields.
#
# Tests cover:
#   - Logged-in owner viewing own item → 200
#   - Different logged-in user viewing another owner's item → 200 (public access)
#   - Unauthenticated visitor → 200 (no login guard)
#   - Unattached item (no computer_id) → 200

require "test_helper"

class SoftwareItemsControllerTest < ActionDispatch::IntegrationTest
  # ── show — logged in as the owner ─────────────────────────────────────────

  test "show returns 200 for a fully populated item when logged in as owner" do
    # alice_vms has software_name (VMS), condition (Complete), version, description,
    # and is installed on alice_pdp11 — exercises all branches of the show view.
    item = software_items(:alice_vms)
    login_as owners(:one)

    get software_item_url(item)

    assert_response :success
  end

  test "show returns 200 for an unattached item when logged in as owner" do
    # alice_rt11_spare has no computer_id — exercises the
    # "Not installed on any hardware" branch in the view.
    item = software_items(:alice_rt11_spare)
    login_as owners(:one)

    get software_item_url(item)

    assert_response :success
  end

  test "show returns 200 for an item with optional fields absent" do
    # bob_rsts has no software_condition and no version — exercises the
    # optional-field fallback paths (show "—").
    item = software_items(:bob_rsts)
    login_as owners(:two)

    get software_item_url(item)

    assert_response :success
  end

  # ── show — different logged-in user (public access) ───────────────────────

  test "show returns 200 when a different logged-in owner views the item" do
    # SoftwareItemsController has no ownership guard on show.
    # Any logged-in user may view any item.
    item = software_items(:alice_vms)
    login_as owners(:two)   # bob, not the item owner (alice)

    get software_item_url(item)

    assert_response :success
  end

  # ── show — unauthenticated visitor ────────────────────────────────────────

  test "show returns 200 when not authenticated" do
    # No require_login before_action — show is public.
    item = software_items(:alice_vms)

    get software_item_url(item)

    assert_response :success
  end
end
