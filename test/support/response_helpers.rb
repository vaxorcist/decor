# decor/test/support/response_helpers.rb
# version 1.0
# v1.0 (Session 50): New file.
#   Provides assert_body_includes / refute_body_includes helpers for integration
#   tests that check response body content.
#
#   Problem solved: the default assert_match / refute_match helpers print the
#   ENTIRE "actual" value on failure. For controller tests that check response.body,
#   this dumps the full rendered HTML page (often 5,000–20,000 characters) into the
#   failure message, making it nearly impossible to find the relevant line.
#
#   These helpers truncate the body to 300 characters in the failure message so the
#   assertion context is readable. The full body is still available via response.body
#   in the test session if deeper inspection is needed.
#
#   Usage (in any ActionDispatch::IntegrationTest):
#     assert_body_includes "SN12345"
#     refute_body_includes "PDP8-7891"
#     assert_body_includes "SN12345", "alice_vms serial must appear after filtering"
#
#   Included in ActionDispatch::IntegrationTest via test_helper.rb.

module ResponseHelpers
  # Asserts that the response body contains the given string.
  # On failure, prints a truncated excerpt of the body instead of the full HTML.
  def assert_body_includes(text, msg = nil)
    assert response.body.include?(text),
      msg || "Expected response body to include #{text.inspect}.\n" \
             "Body (first 300 chars): #{response.body.first(300)}…"
  end

  # Asserts that the response body does NOT contain the given string.
  # On failure, prints a truncated excerpt of the body instead of the full HTML.
  def refute_body_includes(text, msg = nil)
    refute response.body.include?(text),
      msg || "Expected response body NOT to include #{text.inspect}.\n" \
             "Body (first 300 chars): #{response.body.first(300)}…"
  end
end
