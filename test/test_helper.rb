# decor/test/test_helper.rb
# version 1.2
# v1.2 (Session 50): Reduced test output verbosity.
#   Two changes:
#
#   1. minitest-reporters ProgressReporter.
#      Replaces the default dot-per-test output with a compact progress bar.
#      Failure details are still printed in full at the end of the run — no
#      information is lost, the run-time noise is just reduced.
#      The gem is already in the Rails default Gemfile (minitest-reporters).
#
#   2. ResponseHelpers included in ActionDispatch::IntegrationTest.
#      Provides assert_body_includes / refute_body_includes which truncate the
#      response body in failure messages to 300 characters. The default
#      assert_match / refute_match dump the entire rendered HTML (often 5,000–
#      20,000 chars) making failure output unreadable. The new helpers keep the
#      message short without hiding any real information.
#      Defined in test/support/response_helpers.rb (v1.0).

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# ── Compact progress bar output ───────────────────────────────────────────────
# ProgressReporter shows a single progress bar during the run and prints all
# failure details in a clean block at the end. Activated for the default "all
# tests" run; individual-file runs (bin/rails test path/to/file.rb) also benefit.
require "minitest/reporters"
Minitest::Reporters.use! Minitest::Reporters::ProgressReporter.new

# Load all support modules from test/support directory.
# ResponseHelpers (v1.0) is picked up here automatically.
Dir[Rails.root.join("test/support/**/*.rb")].sort.each { |f| require f }

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Include authentication helper for centralized password constants and login methods
    include AuthenticationHelper
  end
end

class ActionDispatch::IntegrationTest
  # Authentication helper — login_as and password constants.
  include AuthenticationHelper

  # Response body helpers — assert_body_includes / refute_body_includes.
  # Use these instead of assert_match(text, response.body) to keep failure
  # messages readable (body truncated to 300 chars in the failure output).
  include ResponseHelpers
end
