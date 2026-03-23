# decor/test/controllers/data_transfers_controller_test.rb
# version 1.2
# Session 37: Added test verifying that connection_group_count appears in the
#   import flash message when connection groups are successfully imported.
#   Added build_csv_with_connections private helper (mirrors the one in the
#   service test) so the controller test can build a connections CSV without
#   depending on the service test's helpers.
# v1.1: Fixed three issues found in first test run:
#   1. Auth redirect target: require_login redirects to new_session_path.
#   2. Missing before_action :require_login in controller.
#   3. csv_upload used ActionDispatch::Http::UploadedFile (fails through HTTP layer).
#      Replaced with Rack::Test::UploadedFile.

require "test_helper"

class DataTransfersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @alice = owners(:one)  # admin user
    @bob   = owners(:two)  # regular user
  end

  # ── Authentication guard (all three actions) ─────────────────────────────

  test "show requires login" do
    get data_transfer_path
    assert_redirected_to new_session_path
  end

  test "export requires login" do
    get export_data_transfer_path
    assert_redirected_to new_session_path
  end

  test "import requires login" do
    post import_data_transfer_path, params: { file: nil }
    assert_redirected_to new_session_path
  end

  # ── show ─────────────────────────────────────────────────────────────────

  test "show renders successfully for logged-in owner" do
    login_as(@alice)
    get data_transfer_path
    assert_response :ok
  end

  test "show is accessible to regular (non-admin) users" do
    login_as(@bob)
    get data_transfer_path
    assert_response :ok
  end

  # ── export ───────────────────────────────────────────────────────────────

  test "export returns a CSV file attachment" do
    login_as(@alice)
    get export_data_transfer_path

    assert_response :ok
    assert_equal "text/csv; charset=utf-8", response.content_type
    assert_match "attachment", response.headers["Content-Disposition"]
  end

  test "export filename contains the owner's user_name and today's date" do
    login_as(@alice)
    get export_data_transfer_path

    disposition = response.headers["Content-Disposition"]
    assert_match "alice",         disposition
    assert_match Date.today.to_s, disposition
    assert_match ".csv",          disposition
  end

  test "export response body is valid CSV with correct headers" do
    login_as(@alice)
    get export_data_transfer_path

    csv = CSV.parse(response.body, headers: true)
    assert_equal OwnerExportService::CSV_HEADERS, csv.headers
  end

  test "export contains only the logged-in owner's records" do
    login_as(@bob)
    get export_data_transfer_path

    csv            = CSV.parse(response.body, headers: true)
    serial_numbers = csv.select { |r| r["record_type"] == "computer" }
                        .map    { |r| r["computer_serial_number"] }

    assert_includes serial_numbers, "PDP8-7891"
    assert_includes serial_numbers, "VT100-5432"
    refute_includes serial_numbers, "SN12345"
    refute_includes serial_numbers, "VAX-780-001"
  end

  # ── import — missing file ─────────────────────────────────────────────────

  test "import with no file redirects with alert" do
    login_as(@alice)
    post import_data_transfer_path, params: {}

    assert_redirected_to data_transfer_path
    assert_match "select a CSV file", flash[:alert]
  end

  # ── import — success (devices only) ──────────────────────────────────────

  test "import with valid CSV creates records and shows success notice" do
    login_as(@alice)

    csv_content = CSV.generate(headers: true, force_quotes: true) do |csv|
      csv << OwnerExportService::CSV_HEADERS
      csv << ["computer", "PDP-11/70", nil, "CTRL-TEST-SN-01",
              nil, nil, nil, nil, nil, nil, nil, nil]
    end

    assert_difference "Computer.count", 1 do
      post import_data_transfer_path, params: { file: csv_upload(csv_content) }
    end

    assert_redirected_to data_transfer_path
    assert_match "Successfully imported", flash[:notice]
    assert_match "1 computer",            flash[:notice]
  end

  test "import creates records for the logged-in owner, not someone else" do
    login_as(@bob)

    csv_content = CSV.generate(headers: true, force_quotes: true) do |csv|
      csv << OwnerExportService::CSV_HEADERS
      csv << ["computer", "PDP-11/70", nil, "CTRL-BOB-SN-01",
              nil, nil, nil, nil, nil, nil, nil, nil]
    end

    post import_data_transfer_path, params: { file: csv_upload(csv_content) }

    computer = Computer.find_by!(serial_number: "CTRL-BOB-SN-01")
    assert_equal @bob, computer.owner
  end

  # ── import — connection groups in flash (Session 37) ─────────────────────

  test "import flash includes connection group count when groups are imported" do
    login_as(@alice)

    # alice_pdp11 (SN12345, PDP-11/70) and alice_vax (VAX-780-001, VAX-11/780)
    # already exist as alice's fixture computers — use them as connection members.
    csv_content = build_csv_with_connections([], [
      { type: nil, label: "Controller test group",
        members: [
          { model: "PDP-11/70",  serial: "SN12345"     },
          { model: "VAX-11/780", serial: "VAX-780-001" }
        ] }
    ])

    assert_difference "ConnectionGroup.count", 1 do
      post import_data_transfer_path, params: { file: csv_upload(csv_content) }
    end

    assert_redirected_to data_transfer_path
    assert_match "Successfully imported",  flash[:notice]
    assert_match "1 connection group",     flash[:notice]
  end

  test "import flash omits connection group count when no groups are imported" do
    login_as(@alice)

    csv_content = CSV.generate(headers: true, force_quotes: true) do |csv|
      csv << OwnerExportService::CSV_HEADERS
      csv << ["computer", "PDP-11/70", nil, "CTRL-NOGROUP-SN",
              nil, nil, nil, nil, nil, nil, nil, nil]
    end

    post import_data_transfer_path, params: { file: csv_upload(csv_content) }

    assert_redirected_to data_transfer_path
    assert_match    "Successfully imported", flash[:notice]
    assert_no_match "connection group",      flash[:notice]
  end

  # ── import — service error ────────────────────────────────────────────────

  test "import with unknown computer model shows alert and no records saved" do
    login_as(@alice)

    csv_content = CSV.generate(headers: true, force_quotes: true) do |csv|
      csv << OwnerExportService::CSV_HEADERS
      csv << ["computer", "Nonexistent Model XYZ", nil, "ERR-SN-01",
              nil, nil, nil, nil, nil, nil, nil, nil]
    end

    assert_no_difference "Computer.count" do
      post import_data_transfer_path, params: { file: csv_upload(csv_content) }
    end

    assert_redirected_to data_transfer_path
    assert_match "Import failed", flash[:alert]
  end

  private

  # Wrap a CSV string in a Rack::Test::UploadedFile so it survives the integration
  # test HTTP layer with .path / .content_type / .original_filename intact.
  # ActionDispatch::Http::UploadedFile gets stringified through post params: and
  # must NOT be used here (causes NoMethodError on .content_type in the controller).
  def csv_upload(content, filename: "test_import.csv", content_type: "text/csv")
    tempfile = Tempfile.new(["ctrl_import_test", ".csv"])
    tempfile.write(content)
    tempfile.rewind
    tempfile.close

    Rack::Test::UploadedFile.new(tempfile.path, content_type, false,
                                  original_filename: filename)
  end

  # Build a CSV with an optional device section followed by the connections sentinel
  # and connection_group/member rows.
  # Mirrors the helper in OwnerImportServiceTest — needed here because controller
  # tests cannot call service-test helpers.
  def build_csv_with_connections(device_rows, connection_groups_data)
    CSV.generate(headers: true, force_quotes: true) do |csv|
      csv << OwnerExportService::CSV_HEADERS
      device_rows.each { |row| csv << row }
      csv << ["! --- connections ---"]
      connection_groups_data.each do |g|
        csv << ["connection_group", g[:type], g[:label],
                nil, nil, nil, nil, nil, nil, nil, nil, nil]
        g[:members].each do |m|
          csv << ["connection_member", m[:model], nil, m[:serial],
                  nil, nil, nil, nil, nil, nil, nil, nil]
        end
      end
    end
  end
end
