# decor/test/controllers/admin/component_order_numbers_controller_test.rb
# version 1.1
# v1.1 (Session 71 — test repair): Same root cause as
#   component_order_number_revalidation_service_test.rb v1.1 — each
#   Component.create! for owner three + memory_board with no explicit
#   serial_number collides with the charlie_vt100_terminal fixture
#   ("-"/"-") under Session 70's widened uniqueness scope. Added explicit
#   serial_number values.
# NEW (Session 65): Auth + behaviour coverage for
# Admin::ComponentOrderNumbersController#revalidate and #unvalidated.
#
# Pattern mirrors admin/component_suggestions_controller_test.rb (Session 63):
# owners(:one) is the admin fixture, owners(:two) is the non-admin fixture,
# login_as needs no explicit password, and non-admin access redirects to
# root_path. Test components are created fresh in-test, assigned to the
# neutral owner (owners(:three)), so no hardcoded count assumes anything
# about alice's or bob's fixture data.
#
# Note: because both actions in this controller operate on ALL Component
# records project-wide (not scoped to a single owner), these tests assert on
# the SPECIFIC records they create — never on total counts — since the test
# database also contains the components.yml fixtures.

require "test_helper"

module Admin
  class ComponentOrderNumbersControllerTest < ActionDispatch::IntegrationTest
    def setup
      @admin          = owners(:one)
      @non_admin      = owners(:two)
      @neutral_owner  = owners(:three)
      @component_type = component_types(:memory_board)
    end

    # ── revalidate ───────────────────────────────────────────────────────────

    test "revalidate re-syncs order_number_verified and redirects with a flash" do
      login_as(@admin)

      suggestion = component_suggestions(:rev_a3_rom)
      component  = Component.create!(
        owner:                  @neutral_owner,
        component_type:         @component_type,
        order_number:           suggestion.order_number,
        order_number_verified:  false,
        serial_number:          "SN-#{SecureRandom.hex(4)}" # avoids colliding with charlie_vt100_terminal ("-"/"-")
      )

      post admin_revalidate_component_order_numbers_url

      assert_redirected_to admin_component_suggestions_path
      assert_match(/Re-validated order numbers/i, flash[:notice])
      assert component.reload.order_number_verified,
             "The matching component should have been flipped to verified by the request"
    end

    test "revalidate flips a stale verified component back to unverified" do
      login_as(@admin)

      component = Component.create!(
        owner:          @neutral_owner,
        component_type: @component_type,
        order_number:   "STALE-#{SecureRandom.hex(4)}",
        serial_number:  "SN-#{SecureRandom.hex(4)}" # avoids colliding with charlie_vt100_terminal ("-"/"-")
      )
      component.update_column(:order_number_verified, true) # force a stale state

      post admin_revalidate_component_order_numbers_url

      assert_redirected_to admin_component_suggestions_path
      assert_not component.reload.order_number_verified
    end

    test "non-admin cannot trigger revalidate" do
      login_as(@non_admin)

      component = Component.create!(
        owner:                  @neutral_owner,
        component_type:         @component_type,
        order_number:           component_suggestions(:delqa).order_number,
        order_number_verified:  false,
        serial_number:          "SN-#{SecureRandom.hex(4)}" # avoids colliding with charlie_vt100_terminal ("-"/"-")
      )

      post admin_revalidate_component_order_numbers_url

      assert_redirected_to root_path
      assert_not component.reload.order_number_verified,
                 "A blocked non-admin request must not have run the revalidation service"
    end

    # ── unvalidated ──────────────────────────────────────────────────────────

    test "unvalidated streams a CSV of components with unverified order_numbers" do
      login_as(@admin)

      component = Component.create!(
        owner:                  @neutral_owner,
        component_type:         @component_type,
        order_number:           "NEEDS-REVIEW-#{SecureRandom.hex(4)}",
        order_number_verified:  false,
        serial_number:          "SN-#{SecureRandom.hex(4)}" # avoids colliding with charlie_vt100_terminal ("-"/"-")
      )

      get admin_unvalidated_component_order_numbers_url

      assert_response :success
      assert_equal "text/csv", response.media_type
      assert_match(/attachment/, response.headers["Content-Disposition"])
      assert_body_includes component.order_number
    end

    test "non-admin cannot download unvalidated order numbers" do
      login_as(@non_admin)

      get admin_unvalidated_component_order_numbers_url

      assert_redirected_to root_path
    end
  end
end
