# decor/test/controllers/admin/run_statuses_controller_test.rb - version 1.1
# Refactored to use centralized AuthenticationHelper
# Removed local log_in_as method - now inherited from test/support/authentication_helper.rb
# All login_as() calls use auto-detection for correct password

require "test_helper"

module Admin
  class RunStatusesControllerTest < ActionDispatch::IntegrationTest
    def setup
      @admin = owners(:one)
      @run_status = run_statuses(:working)
    end

    # Index
    test "index displays run statuses" do
      login_as(@admin)

      get admin_run_statuses_url

      assert_response :success
      assert_select "h1", "Run Statuses"
      assert_select "td", @run_status.name
    end

    # New
    test "new displays form" do
      login_as(@admin)

      get new_admin_run_status_url

      assert_response :success
      assert_select "h1", "New Run Status"
      assert_select "input[name='run_status[name]']"
    end

    # Create
    test "create adds new run status" do
      login_as(@admin)

      assert_difference "RunStatus.count", 1 do
        post admin_run_statuses_url, params: {
          run_status: { name: "New Status" }
        }
      end

      assert_redirected_to admin_run_statuses_path
      assert_match /successfully created/i, flash[:notice]
    end

    test "create fails with blank name" do
      login_as(@admin)

      assert_no_difference "RunStatus.count" do
        post admin_run_statuses_url, params: {
          run_status: { name: "" }
        }
      end

      assert_response :unprocessable_entity
    end

    test "create fails with duplicate name" do
      login_as(@admin)

      assert_no_difference "RunStatus.count" do
        post admin_run_statuses_url, params: {
          run_status: { name: @run_status.name }
        }
      end

      assert_response :unprocessable_entity
    end

    # Edit
    test "edit displays form" do
      login_as(@admin)

      get edit_admin_run_status_url(@run_status)

      assert_response :success
      assert_select "h1", "Edit Run Status"
      assert_select "input[value='#{@run_status.name}']"
    end

    # Update
    test "update changes run status" do
      login_as(@admin)

      patch admin_run_status_url(@run_status), params: {
        run_status: { name: "Updated Name" }
      }

      assert_redirected_to admin_run_statuses_path
      @run_status.reload
      assert_equal "Updated Name", @run_status.name
    end

    test "update fails with blank name" do
      login_as(@admin)
      original_name = @run_status.name

      patch admin_run_status_url(@run_status), params: {
        run_status: { name: "" }
      }

      assert_response :unprocessable_entity
      @run_status.reload
      assert_equal original_name, @run_status.name
    end

    test "update fails with duplicate name" do
      login_as(@admin)
      other = RunStatus.create!(name: "Other Status")

      patch admin_run_status_url(other), params: {
        run_status: { name: @run_status.name }
      }

      assert_response :unprocessable_entity
      other.reload
      assert_equal "Other Status", other.name
    end

    # Destroy
    test "destroy deletes run status without computers" do
      login_as(@admin)
      run_status = RunStatus.create!(name: "Deletable")

      assert_difference "RunStatus.count", -1 do
        delete admin_run_status_url(run_status)
      end

      assert_redirected_to admin_run_statuses_path
    end

    test "destroy fails when run status has computers" do
      login_as(@admin)
      # @run_status has computers via fixtures

      assert_no_difference "RunStatus.count" do
        delete admin_run_status_url(@run_status)
      end

      assert_redirected_to admin_run_statuses_path
    end

    # Authorization
    test "non-admin cannot access run statuses" do
      non_admin = owners(:two)
      login_as(non_admin)  # Auto-detects bob's password

      get admin_run_statuses_url

      assert_redirected_to root_path
    end

    test "non-admin cannot manage run statuses" do
      non_admin = owners(:two)
      login_as(non_admin)  # Auto-detects bob's password
      run_status = run_statuses(:working)

      get new_admin_run_status_url
      assert_redirected_to root_path

      assert_no_difference "RunStatus.count" do
        post admin_run_statuses_url, params: { run_status: { name: "Blocked" } }
      end
      assert_redirected_to root_path

      get edit_admin_run_status_url(run_status)
      assert_redirected_to root_path

      patch admin_run_status_url(run_status), params: { run_status: { name: "Blocked" } }
      assert_redirected_to root_path

      assert_no_difference "RunStatus.count" do
        delete admin_run_status_url(run_status)
      end
      assert_redirected_to root_path
    end
  end
end
