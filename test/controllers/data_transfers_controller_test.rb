# decor/test/controllers/data_transfers_controller_test.rb - version 1.1
# Fixed 3 issues found in the first test run:
#
# 1. Auth redirect target: require_login redirects to new_session_path (not root_path).
#    The three "requires_login" tests were asserting root_path — corrected.
#
# 2. Missing before_action in controller: DataTransfersController was not calling
#    require_login. Fixed in controller v1.1 — show/export/import are now all guarded.
#
# 3. csv_upload helper used ActionDispatch::Http::UploadedFile, which gets stringified
#    when passed through the integration test HTTP layer, causing NoMethodError on
#    .content_type. Replaced with Rack::Test::UploadedFile.new(path, content_type)
#    which integration tests handle correctly.

require "test_helper"

class DataTransfersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @alice = owners(:one)  # admin user
    @bob   = owners(:two)  # regular user
  end

  # ── Authentication guard (all three actions) ─────────────────────────────
  # require_login (Authentication concern) redirects to new_session_path.

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
    assert_match "alice",          disposition
    assert_match Date.today.to_s,  disposition
    assert_match ".csv",           disposition
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

    csv = CSV.parse(response.body, headers: true)
    serial_numbers = csv
      .select { |row| row["record_type"] == "computer" }
      .map    { |row| row["computer_serial_number"] }

    # Bob's computers must be present
    assert_includes serial_numbers, "PDP8-7891"
    assert_includes serial_numbers, "VT100-5432"

    # Alice's computers must NOT appear
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

  # ── import — success ──────────────────────────────────────────────────────

  test "import with valid CSV creates records and shows success notice" do
    login_as(@alice)

    csv_content = CSV.generate(headers: true, force_quotes: true) do |csv|
      csv << OwnerExportService::CSV_HEADERS
      csv << ["computer", "PDP-11/70", nil, "CTRL-TEST-SN-01",
              nil, nil, nil, nil, nil, nil, nil, nil]
    end

    assert_difference "Computer.count", 1 do
      post import_data_transfer_path,
           params: { file: csv_upload(csv_content) }
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

  # Wrap a CSV string in a Rack::Test::UploadedFile so it survives the
  # integration test HTTP layer with .path / .content_type / .original_filename intact.
  # ActionDispatch::Http::UploadedFile does NOT work here — it gets stringified
  # when passed through post params:, causing NoMethodError on .content_type.
  def csv_upload(content, filename: "test_import.csv", content_type: "text/csv")
    tempfile = Tempfile.new(["ctrl_import_test", ".csv"])
    tempfile.write(content)
    tempfile.rewind
    tempfile.close

    Rack::Test::UploadedFile.new(tempfile.path, content_type, false,
                                  original_filename: filename)
  end
end
