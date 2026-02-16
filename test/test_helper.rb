# decor/test/test_helper.rb - version 1.1
# Updated to load centralized test support modules
# Adds AuthenticationHelper to all test classes for password constants and login methods

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Load all support modules from test/support directory
Dir[Rails.root.join("test/support/**/*.rb")].sort.each { |f| require f }

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Include authentication helper for centralized password constants and login methods
    include AuthenticationHelper

    # Add more helper methods to be used by all tests here...
  end
end

# Integration tests also need the authentication helper
class ActionDispatch::IntegrationTest
  include AuthenticationHelper
end
