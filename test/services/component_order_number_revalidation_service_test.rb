# decor/test/services/component_order_number_revalidation_service_test.rb
# version 1.0
# NEW (Session 65): Tests for ComponentOrderNumberRevalidationService.
#
# All test components are created fresh in-test (not via components.yml
# fixtures) and assigned to owners(:three) — the project's neutral owner
# (see RAILS_SPECIFICS.md "Fixture Ownership") — so this suite never
# hardcodes a count that depends on alice's or bob's fixture data.
#
# Existing components.yml fixtures (pdp11_memory, pdp11_cpu, spare_disk,
# pdp8_memory, spare_power_supply, charlie_vt100_terminal) all have a BLANK
# order_number and order_number_verified defaulting to false — i.e. they are
# already in the "correctly unverified" state before any test runs. They
# contribute to the unchanged_count baseline but never need special handling:
# every assertion below is derived from Component.count / the specific
# records created in each test, never from a hardcoded total.

require "test_helper"

class ComponentOrderNumberRevalidationServiceTest < ActiveSupport::TestCase
  def setup
    @neutral_owner   = owners(:three) # charlie — no hardcoded count assertions elsewhere
    @component_type  = component_types(:memory_board)
  end

  test "flips a component to verified when its order_number matches a suggestion" do
    suggestion = component_suggestions(:delqa)
    component  = Component.create!(
      owner:                  @neutral_owner,
      component_type:         @component_type,
      order_number:           suggestion.order_number,
      order_number_verified:  false
    )

    ComponentOrderNumberRevalidationService.call

    assert component.reload.order_number_verified,
           "Component should become verified once its order_number matches a ComponentSuggestion"
  end

  test "flips a component to unverified when its order_number no longer matches any suggestion" do
    component = Component.create!(
      owner:          @neutral_owner,
      component_type: @component_type,
      order_number:   "STALE-#{SecureRandom.hex(4)}"
    )
    # Force a stale "verified" state directly at the DB layer — this simulates
    # a ComponentSuggestion having been deleted or edited after the component
    # was originally verified against it. update_column bypasses validations/
    # callbacks deliberately, mirroring how the service itself writes.
    component.update_column(:order_number_verified, true)

    ComponentOrderNumberRevalidationService.call

    assert_not component.reload.order_number_verified,
               "Component should become unverified once its order_number no longer matches any suggestion"
  end

  test "treats a blank order_number as always unverified" do
    component = Component.create!(owner: @neutral_owner, component_type: @component_type, order_number: nil)
    component.update_column(:order_number_verified, true) # force an inconsistent state to prove the sync corrects it

    ComponentOrderNumberRevalidationService.call

    assert_not component.reload.order_number_verified,
               "A component with no order_number can never be considered verified"
  end

  test "returns counts that add up to the total component count" do
    to_verify = Component.create!(
      owner:                  @neutral_owner,
      component_type:         @component_type,
      order_number:           component_suggestions(:m7516).order_number,
      order_number_verified:  false
    )
    to_unverify = Component.create!(
      owner:          @neutral_owner,
      component_type: @component_type,
      order_number:   "STALE-#{SecureRandom.hex(4)}"
    )
    to_unverify.update_column(:order_number_verified, true)

    total_before = Component.count
    result = ComponentOrderNumberRevalidationService.call

    assert to_verify.reload.order_number_verified
    assert_not to_unverify.reload.order_number_verified
    assert result[:verified_count]   >= 1
    assert result[:unverified_count] >= 1
    assert_equal total_before,
                 result[:verified_count] + result[:unverified_count] + result[:unchanged_count],
                 "The three returned counts must account for every component exactly once"
  end

  test "is idempotent — a second consecutive run makes zero further changes" do
    suggestion = component_suggestions(:pcb_assembly)
    Component.create!(
      owner:                  @neutral_owner,
      component_type:         @component_type,
      order_number:           suggestion.order_number,
      order_number_verified:  false
    )

    ComponentOrderNumberRevalidationService.call # first run does the real work
    second_result = ComponentOrderNumberRevalidationService.call # should be a no-op

    assert_equal 0, second_result[:verified_count]
    assert_equal 0, second_result[:unverified_count]
    assert_equal Component.count, second_result[:unchanged_count]
  end
end
