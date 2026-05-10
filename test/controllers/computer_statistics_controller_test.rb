# decor/test/controllers/computer_statistics_controller_test.rb
# version 1.1
# v1.1 (Session 61): Adjusted for zero-count exclusion.
#   PDP-10 has 0 registered computers in fixtures and is now excluded by the
#   controller (.reject { |s| s[:count] == 0 }).  Tests updated accordingly:
#     - "shows all computer model names" now refutes PDP-10.
#     - sort tests no longer reference PDP-10 as an expected model.
# v1.0 (Session 61): New controller test — Computers Statistics page.
#   Tests GET /computer_statistics without login (public page).
#   Verifies:
#     1. 200 OK for all four sort options.
#     2. Computer model names appear in the response body.
#     3. Peripheral model names (hsc50 = "HSC50", dec_vt278 = "DEC VT278")
#        are NOT present — the page scopes to device_type: computer only.
#     4. Search filter narrows results correctly.
#
#   Fixture overview (relevant to these tests):
#     Computer models (device_type: 0 = computer):
#       pdp11_70  → "PDP-11/70"  — referenced by alice_pdp11 + unassigned_condition_test = 2 computers
#       vax11_780 → "VAX-11/780" — referenced by alice_vax = 1 computer
#       pdp8      → "PDP-8"      — referenced by bob_pdp8 = 1 computer
#       vt100     → "VT100"      — referenced by bob_vt100 = 1 computer
#       pdp10     → "PDP-10"     — no computers registered = 0
#
#     Peripheral models (device_type: 2 = peripheral — must NOT appear):
#       hsc50     → "HSC50"
#       dec_vt278 → "DEC VT278"
#
#   Note: dec_unibus_router and charlie_dec_vt278 are device_type: 2 peripherals
#   that reference computer models (pdp11_70, vt100). The controller uses
#   Computer.where(device_type: "computer").group(:computer_model_id).count
#   so those peripherals are excluded from the count even though they reference
#   computer-class models.

require "test_helper"

class ComputerStatisticsControllerTest < ActionDispatch::IntegrationTest
  # ── Basic access ────────────────────────────────────────────────────────────

  test "GET index is publicly accessible without login" do
    get computer_statistics_path
    assert_response :success
  end

  # ── Computer models present ──────────────────────────────────────────────────

  test "GET index shows all computer model names" do
    get computer_statistics_path
    assert_response :success
    assert_body_includes "PDP-11/70"
    assert_body_includes "VAX-11/780"
    assert_body_includes "PDP-8"
    assert_body_includes "VT100"
    # PDP-10 has 0 computers — excluded by controller
    refute_body_includes "PDP-10"
  end

  # ── Peripheral models excluded ───────────────────────────────────────────────

  test "GET index does not show peripheral models" do
    get computer_statistics_path
    assert_response :success
    # HSC50 is a peripheral model (device_type: 2) — must not appear
    refute_body_includes "HSC50"
    # DEC VT278 is a peripheral model (device_type: 2) — must not appear
    refute_body_includes "DEC VT278"
  end

  # ── Sort options — all return 200 and include expected content ───────────────

  test "GET index with sort=most_common returns 200" do
    get computer_statistics_path(sort: "most_common")
    assert_response :success
    # PDP-11/70 has the highest count (2) — must be present
    assert_body_includes "PDP-11/70"
    # PDP-10 has 0 — excluded
    refute_body_includes "PDP-10"
  end

  test "GET index with sort=least_common returns 200" do
    get computer_statistics_path(sort: "least_common")
    assert_response :success
    # PDP-10 has 0 computers — excluded; least-common shown model has count >= 1
    refute_body_includes "PDP-10"
    # PDP-8, VAX-11/780, VT100 all have count 1 — shown first on least_common
    assert_body_includes "PDP-8"
    assert_body_includes "PDP-11/70"
  end

  test "GET index with sort=model_asc returns 200" do
    get computer_statistics_path(sort: "model_asc")
    assert_response :success
    # PDP-10 excluded (count 0); first shown is PDP-11/70 alphabetically
    refute_body_includes "PDP-10"
    assert_body_includes "PDP-11/70"
    assert_body_includes "VT100"
  end

  test "GET index with sort=model_desc returns 200" do
    get computer_statistics_path(sort: "model_desc")
    assert_response :success
    # Reverse alphabetical order: VT100 comes first
    assert_body_includes "VT100"
    # PDP-10 excluded (count 0)
    refute_body_includes "PDP-10"
  end

  # ── Unknown sort param falls back to most_common ─────────────────────────────

  test "GET index with unrecognised sort param returns 200" do
    get computer_statistics_path(sort: "bogus_sort")
    assert_response :success
    assert_body_includes "PDP-11/70"
  end

  # ── Search filter ────────────────────────────────────────────────────────────

  test "GET index with query=PDP shows only PDP models" do
    get computer_statistics_path(query: "PDP")
    assert_response :success
    assert_body_includes "PDP-11/70"
    assert_body_includes "PDP-8"
    # PDP-10 has 0 computers — excluded even when query matches
    refute_body_includes "PDP-10"
    # VAX-11/780 and VT100 do not match "PDP"
    refute_body_includes "VAX-11/780"
    refute_body_includes "VT100"
  end

  test "GET index with query that matches nothing returns 200 with no model rows" do
    get computer_statistics_path(query: "ZZZNOMATCH")
    assert_response :success
    refute_body_includes "PDP-11/70"
    refute_body_includes "PDP-8"
  end

  # ── Reset link is present ────────────────────────────────────────────────────

  test "GET index renders Reset link pointing to computer_statistics_path" do
    get computer_statistics_path
    assert_body_includes computer_statistics_path
  end
end
