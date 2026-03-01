# decor/test/controllers/components_controller_test.rb
# ADD these tests to the existing file (version bump to next version)
# Tests for destroy action source=owner redirect — added Session 11

# ---------------------------------------------------------------------------
# Destroy — source=owner redirect
# ---------------------------------------------------------------------------

test "destroy with source=owner redirects to owner page" do
  login_as owners(:one) # alice
  assert_difference "Component.count", -1 do
    delete component_url(components(:pdp11_cpu)), params: { source: "owner" }
  end
  assert_redirected_to owner_path(owners(:one))
  assert_equal "Component was successfully deleted.", flash[:notice]
end

test "destroy without source redirects to components index" do
  login_as owners(:one) # alice
  assert_difference "Component.count", -1 do
    delete component_url(components(:pdp11_cpu))
  end
  assert_redirected_to components_path
  assert_equal "Component was successfully deleted.", flash[:notice]
end

test "destroy with source=computer redirects to computer edit page" do
  # Existing source=computer behaviour — verify it was not broken by the
  # source=owner branch added in Session 11.
  login_as owners(:one) # alice
  assert_difference "Component.count", -1 do
    delete component_url(components(:pdp11_cpu)), params: { source: "computer" }
  end
  assert_redirected_to edit_computer_path(computers(:alice_pdp11))
  assert_equal "Component was successfully deleted.", flash[:notice]
end
