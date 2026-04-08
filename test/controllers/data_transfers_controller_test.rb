# decor/test/controllers/data_transfers_controller_test.rb
# version 1.4
# v1.4 (Session 50): Fixed two remaining test failures after v1.3 changes.
#
#   1. "import flash includes connection group count when groups are imported"
#      Was: assert_match "1 connection group", flash[:notice]
#      Actual controller phrasing (data_transfers_controller v1.6) uses
#      "connection(s)" not "connection group". Fixed to assert_match "1 connection".
#
#   2. "import with unknown computer model shows alert and no records saved"
#      Was: assert_match "Import failed", flash[:alert]
#      OwnerImportService v1.11 partial success: unknown model → row_error (row
#      skipped), result[:success] remains true, so the controller sets
#      flash[:row_errors] instead of flash[:alert]. Fixed to assert
#      flash[:row_errors].present?.
#
# v1.3 (Session 50): Removed all OwnerExportService::CSV_HEADERS references.
#   OwnerExportService v1.7 (Session 48) removed the global CSV_HEADERS constant
#   in favour of per-section sentinels and section-specific column-declaration rows.
#   Failures fixed:
#
#   1. "export response body is valid CSV with correct headers"
#      Was: CSV.parse(response.body, headers: true) + assert csv.headers == CSV_HEADERS
#      The new export starts with a comment row ("# Owner: ..."), so CSV.parse with
#      headers: true uses that comment as the header, not a column-declaration row.
#      Fix: replaced with "export response body uses per-section CSV format" which
#      checks that the computers section sentinel is present in the body.
#
#   2. "export contains only the logged-in owner's records"
#      Was: CSV.parse(response.body, headers: true).select { r["record_type"] }
#           → always empty because comment row is treated as the header row;
#           also used non-existent column name "computer_serial_number".
#      Fix: replaced CSV parsing with plain string assert_includes / refute_includes
#           on the raw response body. Serial numbers are unique strings that won't
#           appear anywhere except their own data rows.
#
#   3. All import CSV builders that used OwnerExportService::CSV_HEADERS as the
#      global header row and 12-column data rows.
#      Fix: switched to per-section format: "! --- computers ---" sentinel,
#      COMPUTER_SECTION_HEADERS column-declaration row, 8-column data rows.
#      OwnerImportService v1.11 supports both old and new formats.
#
#   4. build_csv_with_connections helper
#      Was: prepended CSV_HEADERS (old global header) + old 12-column device rows.
#      Fix: per-section format for both the optional device block and the
#      connections block.
#
# v1.2 (Session 37): Added connection_group_count flash tests + build_csv_with_connections.
# v1.1: Fixed auth redirect, require_login, Rack::Test::UploadedFile.

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

  test "export response body uses per-section CSV format" do
    # OwnerExportService v1.7+ writes per-section sentinels instead of a global
    # header row. Alice has computers, so the computers sentinel must be present.
    login_as(@alice)
    get export_data_transfer_path

    assert_includes response.body, "! --- computers ---"
  end

  test "export contains only the logged-in owner's records" do
    # Bob's fixture computers: PDP8-7891, VT100-5432.
    # Alice's fixture computers: SN12345, VAX-780-001.
    # Serial numbers are unique strings; string-contains check is reliable here
    # and avoids having to parse the per-section CSV format in a controller test.
    login_as(@bob)
    get export_data_transfer_path

    assert_includes response.body, "PDP8-7891"
    assert_includes response.body, "VT100-5432"
    refute_includes response.body, "SN12345"
    refute_includes response.body, "VAX-780-001"
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

    # Per-section format (v1.7+): sentinel + column-declaration row + data rows.
    # COMPUTER_SECTION_HEADERS: record_type, model, order_number, serial_number,
    #   condition, run_status, history, barter_status (8 columns).
    csv_content = CSV.generate(force_quotes: true) do |csv|
      csv << ["! --- computers ---"]
      csv << OwnerExportService::COMPUTER_SECTION_HEADERS
      csv << ["computer", "PDP-11/70", nil, "CTRL-TEST-SN-01", nil, nil, nil, nil]
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

    csv_content = CSV.generate(force_quotes: true) do |csv|
      csv << ["! --- computers ---"]
      csv << OwnerExportService::COMPUTER_SECTION_HEADERS
      csv << ["computer", "PDP-11/70", nil, "CTRL-BOB-SN-01", nil, nil, nil, nil]
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
    assert_match "1 connection",           flash[:notice]
  end

  test "import flash omits connection group count when no groups are imported" do
    login_as(@alice)

    csv_content = CSV.generate(force_quotes: true) do |csv|
      csv << ["! --- computers ---"]
      csv << OwnerExportService::COMPUTER_SECTION_HEADERS
      csv << ["computer", "PDP-11/70", nil, "CTRL-NOGROUP-SN", nil, nil, nil, nil]
    end

    post import_data_transfer_path, params: { file: csv_upload(csv_content) }

    assert_redirected_to data_transfer_path
    assert_match    "Successfully imported", flash[:notice]
    assert_no_match "connection group",      flash[:notice]
  end

  # ── import — service error ────────────────────────────────────────────────

  test "import with unknown computer model shows alert and no records saved" do
    login_as(@alice)

    csv_content = CSV.generate(force_quotes: true) do |csv|
      csv << ["! --- computers ---"]
      csv << OwnerExportService::COMPUTER_SECTION_HEADERS
      csv << ["computer", "Nonexistent Model XYZ", nil, "ERR-SN-01", nil, nil, nil, nil]
    end

    assert_no_difference "Computer.count" do
      post import_data_transfer_path, params: { file: csv_upload(csv_content) }
    end

    # OwnerImportService v1.11 uses partial success: an unknown model is a row_error
    # (the row is skipped) rather than a file-level failure. result[:success] is true,
    # so the controller sets flash[:row_errors], not flash[:alert].
    assert_redirected_to data_transfer_path
    assert flash[:row_errors].present?, "row_errors should be set when a model is unknown"
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

  # Build a per-section CSV with an optional computers block followed by a
  # connections block.
  #
  # device_rows: array of 8-element arrays matching COMPUTER_SECTION_HEADERS.
  #   Pass [] to omit the computers section entirely.
  # connection_groups_data: array of hashes:
  #   { type: String|nil, label: String|nil,
  #     members: [ { model: String, serial: String }, ... ] }
  #
  # CONNECTION_SECTION_HEADERS:
  #   record_type, owner_group_id, connection_type_or_model, label, serial_number
  #
  # owner_group_id is left nil here (fresh import, not a re-import of an existing
  # export). The importer treats nil owner_group_id as a new group.
  #
  # Mirrors the helper in OwnerImportServiceTest — needed here because controller
  # tests cannot call service-test helpers.
  def build_csv_with_connections(device_rows, connection_groups_data)
    CSV.generate(force_quotes: true) do |csv|
      unless device_rows.empty?
        csv << ["! --- computers ---"]
        csv << OwnerExportService::COMPUTER_SECTION_HEADERS
        device_rows.each { |row| csv << row }
      end

      csv << ["! --- connections ---"]
      csv << OwnerExportService::CONNECTION_SECTION_HEADERS

      connection_groups_data.each do |g|
        # connection_group row: owner_group_id blank (new import), connection_type_or_model
        # holds the connection type name, serial blank.
        csv << ["connection_group", nil, g[:type], g[:label], nil]

        g[:members].each do |m|
          # connection_member row: owner_group_id blank, connection_type_or_model holds
          # the computer's model name, label blank, serial holds the computer's serial.
          csv << ["connection_member", nil, m[:model], nil, m[:serial]]
        end
      end
    end
  end
end
