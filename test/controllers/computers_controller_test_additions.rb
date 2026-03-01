# decor/test/controllers/computers_controller_test.rb
# ADD these tests to the existing file (version bump to next version)
# Tests for destroy action source=owner redirect — added Session 11

# ---------------------------------------------------------------------------
# Destroy — source=owner redirect
# ---------------------------------------------------------------------------

test "destroy with source=owner redirects to owner page" do
  login_as owners(:one) # alice
  assert_difference "Computer.count", -1 do
    delete computer_url(computers(:alice_pdp11)), params: { source: "owner" }
  end
  assert_redirected_to owner_path(owners(:one))
  assert_equal "Computer was successfully deleted.", flash[:notice]
end

test "destroy without source redirects to computers index" do
  login_as owners(:one) # alice
  assert_difference "Computer.count", -1 do
    delete computer_url(computers(:alice_pdp11))
  end
  assert_redirected_to computers_path
  assert_equal "Computer was successfully deleted.", flash[:notice]
end
