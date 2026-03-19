# decor/test/controllers/admin/connection_types_controller_test.rb
# version 1.0
# Session 33: Part 2 — Admin ConnectionTypes CRUD tests.
# Mirrors Admin::ComponentTypesControllerTest pattern.
#
# Fixture layout:
#   rs232    — has connection_groups (bob_pdp8_vt100 in connection_groups.yml)
#              → destroy must fail (restrict_with_error)
#   ethernet — no connection_groups → destroy must succeed
#
# destroy failure path: controller sets flash[:alert] (not flash[:notice])
# because the return value of destroy is checked explicitly.

require "test_helper"

module Admin
  class ConnectionTypesControllerTest < ActionDispatch::IntegrationTest
    def setup
      @admin = owners(:one)
      @connection_type = connection_types(:rs232)  # has connection_groups → cannot delete
    end

    # ── Index ──────────────────────────────────────────────────────────────

    test "index displays connection types" do
      login_as(@admin)

      get admin_connection_types_url

      assert_response :success
      assert_select "h1", "Connection Types"
      assert_select "td", @connection_type.name
    end

    # ── New ────────────────────────────────────────────────────────────────

    test "new displays form" do
      login_as(@admin)

      get new_admin_connection_type_url

      assert_response :success
      assert_select "h1", "New Connection Type"
      assert_select "input[name='connection_type[name]']"
      assert_select "input[name='connection_type[label]']"
    end

    # ── Create ─────────────────────────────────────────────────────────────

    test "create adds new connection type with name only" do
      login_as(@admin)

      assert_difference "ConnectionType.count", 1 do
        post admin_connection_types_url, params: {
          connection_type: { name: "Token Ring", label: "" }
        }
      end

      assert_redirected_to admin_connection_types_path
      assert_match(/successfully created/i, flash[:notice])
    end

    test "create adds new connection type with name and label" do
      login_as(@admin)

      assert_difference "ConnectionType.count", 1 do
        post admin_connection_types_url, params: {
          connection_type: { name: "SCSI", label: "Small Computer System Interface" }
        }
      end

      assert_redirected_to admin_connection_types_path
      created = ConnectionType.find_by!(name: "SCSI")
      assert_equal "Small Computer System Interface", created.label
    end

    test "create fails with blank name" do
      login_as(@admin)

      assert_no_difference "ConnectionType.count" do
        post admin_connection_types_url, params: {
          connection_type: { name: "", label: "" }
        }
      end

      assert_response :unprocessable_entity
    end

    test "create fails with duplicate name" do
      login_as(@admin)

      assert_no_difference "ConnectionType.count" do
        post admin_connection_types_url, params: {
          connection_type: { name: @connection_type.name }
        }
      end

      assert_response :unprocessable_entity
    end

    # ── Edit ───────────────────────────────────────────────────────────────

    test "edit displays form with existing values" do
      login_as(@admin)

      get edit_admin_connection_type_url(@connection_type)

      assert_response :success
      assert_select "h1", "Edit Connection Type"
      assert_select "input[value='#{@connection_type.name}']"
    end

    # ── Update ─────────────────────────────────────────────────────────────

    test "update changes connection type name" do
      login_as(@admin)

      patch admin_connection_type_url(@connection_type), params: {
        connection_type: { name: "RS-232C Serial", label: @connection_type.label }
      }

      assert_redirected_to admin_connection_types_path
      @connection_type.reload
      assert_equal "RS-232C Serial", @connection_type.name
    end

    test "update changes connection type label" do
      login_as(@admin)

      patch admin_connection_type_url(@connection_type), params: {
        connection_type: { name: @connection_type.name, label: "Updated label text" }
      }

      assert_redirected_to admin_connection_types_path
      @connection_type.reload
      assert_equal "Updated label text", @connection_type.label
    end

    test "update fails with blank name" do
      login_as(@admin)
      original_name = @connection_type.name

      patch admin_connection_type_url(@connection_type), params: {
        connection_type: { name: "", label: "" }
      }

      assert_response :unprocessable_entity
      @connection_type.reload
      assert_equal original_name, @connection_type.name
    end

    test "update fails with duplicate name" do
      login_as(@admin)
      other = connection_types(:ethernet)

      patch admin_connection_type_url(other), params: {
        connection_type: { name: @connection_type.name, label: "" }
      }

      assert_response :unprocessable_entity
      other.reload
      assert_equal "Ethernet", other.name
    end

    # ── Destroy ────────────────────────────────────────────────────────────

    test "destroy deletes connection type without groups" do
      login_as(@admin)
      # ethernet has no connection_groups → delete must succeed
      ethernet = connection_types(:ethernet)

      assert_difference "ConnectionType.count", -1 do
        delete admin_connection_type_url(ethernet)
      end

      assert_redirected_to admin_connection_types_path
      assert_match(/successfully deleted/i, flash[:notice])
    end

    test "destroy fails when connection type has groups" do
      login_as(@admin)
      # rs232 has connection_groups via fixtures → restrict_with_error blocks deletion

      assert_no_difference "ConnectionType.count" do
        delete admin_connection_type_url(@connection_type)
      end

      assert_redirected_to admin_connection_types_path
      assert flash[:alert].present?, "Expected flash[:alert] to be set on failed destroy"
    end

    # ── Authorization ──────────────────────────────────────────────────────

    test "non-admin cannot access connection types" do
      non_admin = owners(:two)
      login_as(non_admin)

      get admin_connection_types_url

      assert_redirected_to root_path
    end

    test "non-admin cannot manage connection types" do
      non_admin = owners(:two)
      login_as(non_admin)

      get new_admin_connection_type_url
      assert_redirected_to root_path

      assert_no_difference "ConnectionType.count" do
        post admin_connection_types_url, params: { connection_type: { name: "Blocked" } }
      end
      assert_redirected_to root_path

      get edit_admin_connection_type_url(@connection_type)
      assert_redirected_to root_path

      patch admin_connection_type_url(@connection_type), params: { connection_type: { name: "Blocked" } }
      assert_redirected_to root_path

      assert_no_difference "ConnectionType.count" do
        delete admin_connection_type_url(@connection_type)
      end
      assert_redirected_to root_path
    end
  end
end
