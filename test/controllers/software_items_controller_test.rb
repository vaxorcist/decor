# decor/test/controllers/software_items_controller_test.rb
# version 1.5
# v1.5 (Session 50): Migrated all assert_match/refute_match on response.body to
#   assert_body_includes / refute_body_includes (ResponseHelpers, added in this
#   session). No logic changes — same assertions, shorter failure messages.
#
# v1.4 (Session 50): Fixed 7 test assertion failures caused by sidebar dropdown
#   rendering all software names as <option> elements.
#   Root cause: refute_match on software name strings (e.g. "RSTS/E", "VMS") always
#   failed because those strings appear in the filter sidebar's <option> tags even
#   when no matching data row is present.
#   Fix: all assert/refute_match assertions now use values that only appear in data
#   rows — serial numbers from the "Installed On" column (SN12345, PDP8-7891,
#   RTR-001) and version strings (V5.3, V5.5). None of these appear in sidebar
#   dropdown options.
#   Also fixed the empty state test: refute_match "No software registered yet."
#   was logically inverted — the correct assertion is assert_match.
#
# v1.3 (Session 50): Added search, sort, and filter tests for the index action.
#   New tests cover:
#     Search (query param):
#       - matching query returns the matched item; excludes non-matching items
#       - non-matching query results in no records in the response body
#     Sort smoke tests (sort param):
#       - added_desc, added_asc, name_desc_version_asc, owner_asc_name_asc_version_asc,
#         owner_asc_name_desc_version_asc — each returns 200 and includes a fixture name
#     Filter by software_name_id:
#       - only items for that software name appear; others are excluded
#     Filter by owner_id:
#       - only items for that owner appear; others are excluded
#     Barter filter (logged-in only):
#       - default (no param) excludes "wanted" items
#       - barter_status=2 (wanted only) excludes no_barter/offered items
#       - barter_status=1 (offered only) returns only offered items
#     No barter filter when not logged in:
#       - "wanted" items appear even though they would be filtered for members
#
#   Assertions derive values from fixtures via association lookups — never
#   hardcoded strings. Follows the derive-from-data rule in PROGRAMMING_GENERAL.md.
#
# v1.2 (Session 48): Software feature Session F — index action tests.
# v1.1 (Session 46): Software feature Session D — CRUD controller tests.
# v1.0 (Session 45): Software feature Session C — read-only show tests.
#
# SoftwareItemsController access model:
#   index             — publicly accessible (no login required)
#   show              — publicly accessible (no login required)
#   new / create      — require_login; scoped to Current.owner
#   edit / update     — require_login + must own the record
#   destroy           — require_login + must own the record
#
# Fixtures used:
#   software_items(:alice_vms)        — owner one (alice), barter no_barter (0)
#   software_items(:alice_rt11_spare) — owner one (alice), barter offered (1)
#   software_items(:bob_rsts)         — owner two (bob),   barter no_barter (0)
#   software_items(:charlie_rt11)     — owner three (charlie), barter wanted (2)
#   software_names(:vms)              — software name unique to alice_vms
#   software_names(:rsts_e)           — software name unique to bob_rsts
#   software_names(:rt11)             — shared by alice_rt11_spare and charlie_rt11
#   owners(:one)                      — alice
#   owners(:two)                      — bob
#   owners(:three)                    — charlie (neutral owner; only has wanted items)

require "test_helper"

class SoftwareItemsControllerTest < ActionDispatch::IntegrationTest
  # ═══════════════════════════════════════════════════════════════════════════
  # index — baseline (existing)
  # ═══════════════════════════════════════════════════════════════════════════

  test "index returns 200 when not logged in" do
    get software_items_url

    assert_response :success
  end

  test "index returns 200 when logged in" do
    login_as owners(:one)

    get software_items_url

    assert_response :success
  end

  test "index response body includes a fixture software name" do
    # Derives the expected name from the fixture association — never hardcoded.
    # alice_vms is the richest fixture and is included in every index response.
    # alice_vms has barter_status no_barter (0) so it passes the default 0+1 filter.
    expected_name = software_items(:alice_vms).software_name.name

    login_as owners(:one)
    get software_items_url

    assert_body_includes expected_name
  end

  # ═══════════════════════════════════════════════════════════════════════════
  # index — search (query param)
  # ═══════════════════════════════════════════════════════════════════════════

  test "index with query matching one software name includes it and excludes others" do
    # Assert/refute using serial numbers from the "Installed On" column — these appear
    # only in data rows, not in sidebar dropdown <option> elements (which DO contain
    # all software names, making name-based refute_match unreliable).
    #
    # alice_vms is installed on alice_pdp11 (serial SN12345) and matches query "VMS".
    # bob_rsts is installed on bob_pdp8 (serial PDP8-7891) and does NOT match.
    vms_name = software_items(:alice_vms).software_name.name

    # Not logged in — no barter filter applied; all items are eligible.
    get software_items_url, params: { query: vms_name }

    assert_body_includes "SN12345"   # alice_vms installed-on serial — in the result
    refute_body_includes "PDP8-7891"   # bob_rsts installed-on serial — not in result
  end

  test "index with query that matches nothing shows empty state" do
    get software_items_url, params: { query: "XYZZY_NONEXISTENT_QUERY_12345" }

    # An empty result set renders the empty_state partial.
    assert_body_includes "No software registered yet."
  end

  # ═══════════════════════════════════════════════════════════════════════════
  # index — filter by software_name_id
  # ═══════════════════════════════════════════════════════════════════════════

  test "index filtered by software_name_id includes only that software" do
    # Filter to VMS only. alice_vms (SN12345) must appear; bob_rsts (PDP8-7891) must not.
    # Serial numbers only appear in data rows — safe to use for refute_match.
    vms_id = software_items(:alice_vms).software_name_id

    get software_items_url, params: { software_name_id: vms_id }

    assert_body_includes "SN12345"
    refute_body_includes "PDP8-7891"
  end

  # ═══════════════════════════════════════════════════════════════════════════
  # index — filter by owner_id
  # ═══════════════════════════════════════════════════════════════════════════

  test "index filtered by owner_id includes only that owner's items" do
    # Filter to bob only. bob_rsts (PDP8-7891) must appear; alice_vms (SN12345) must not.
    get software_items_url, params: { owner_id: owners(:two).id }

    assert_body_includes "PDP8-7891"
    refute_body_includes "SN12345"
  end

  # ═══════════════════════════════════════════════════════════════════════════
  # index — barter status filter
  # ═══════════════════════════════════════════════════════════════════════════

  test "index default barter filter for logged-in users excludes wanted items" do
    # charlie (owner :three) has only charlie_rt11 (wanted=2). The default 0+1 filter
    # excludes wanted items. Filtering by owner_id=charlie with default barter yields
    # zero data rows — charlie's installed-on serial (RTR-001) must not appear.
    # RTR-001 appears only in data rows, not in any sidebar dropdown option.
    login_as owners(:one)
    get software_items_url, params: { owner_id: owners(:three).id }

    refute_body_includes "RTR-001"
  end

  test "index barter_status=2 (wanted only) excludes no_barter items" do
    # charlie_rt11 (wanted=2) is installed on dec_unibus_router (serial RTR-001).
    # alice_vms (no_barter=0) is installed on alice_pdp11 (serial SN12345).
    # With wanted-only filter: RTR-001 must appear; SN12345 must not.
    login_as owners(:one)
    get software_items_url, params: { barter_status: "2" }

    assert_body_includes "RTR-001"
    refute_body_includes "SN12345"
  end

  test "index barter_status=1 (offered only) excludes no_barter and wanted items" do
    # alice_rt11_spare (offered=1) is the only offered item. It is unattached (no computer)
    # and has version V5.3. alice_vms (no_barter=0) has version V5.5 and serial SN12345.
    # With offered-only filter: V5.3 must appear; SN12345 (alice_vms serial) must not.
    # Version strings are unique and appear only in data rows.
    login_as owners(:one)
    get software_items_url, params: { barter_status: "1" }

    assert_body_includes "V5.3"
    refute_body_includes "SN12345"
  end

  test "index applies no barter filter when not logged in" do
    # Visitors (not logged in) see all items regardless of barter_status.
    # charlie_rt11 is wanted (2) — would be filtered out for logged-in users
    # by default, but must appear for unauthenticated visitors.
    charlie_name = software_items(:charlie_rt11).software_name.name

    get software_items_url  # no login

    assert_body_includes charlie_name
  end

  # ═══════════════════════════════════════════════════════════════════════════
  # index — sort smoke tests
  # ═══════════════════════════════════════════════════════════════════════════
  # These tests verify that each sort param is accepted and returns a valid
  # response containing fixture data. Exact ordering is not asserted — that
  # would couple tests to fixture insertion order, which is fragile.

  test "index with sort=added_desc returns 200 and includes fixture data" do
    login_as owners(:one)
    get software_items_url, params: { sort: "added_desc" }

    assert_response :success
    assert_body_includes software_items(:alice_vms).software_name.name
  end

  test "index with sort=added_asc returns 200 and includes fixture data" do
    login_as owners(:one)
    get software_items_url, params: { sort: "added_asc" }

    assert_response :success
    assert_body_includes software_items(:alice_vms).software_name.name
  end

  test "index with sort=name_desc_version_asc returns 200 and includes fixture data" do
    login_as owners(:one)
    get software_items_url, params: { sort: "name_desc_version_asc" }

    assert_response :success
    assert_body_includes software_items(:alice_vms).software_name.name
  end

  test "index with sort=owner_asc_name_asc_version_asc returns 200 and includes fixture data" do
    login_as owners(:one)
    get software_items_url, params: { sort: "owner_asc_name_asc_version_asc" }

    assert_response :success
    assert_body_includes software_items(:alice_vms).software_name.name
  end

  test "index with sort=owner_asc_name_desc_version_asc returns 200 and includes fixture data" do
    login_as owners(:one)
    get software_items_url, params: { sort: "owner_asc_name_desc_version_asc" }

    assert_response :success
    assert_body_includes software_items(:alice_vms).software_name.name
  end

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
          software_name_id: software_names(:tops20).id,
          version:          "V6.0",
          barter_status:    "no_barter"
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
    item  = software_items(:alice_vms)
    owner = owners(:one)
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
