# decor/test/controllers/admin/data_transfers_controller_test.rb
# version 1.2
# v1.2 (Session 41): Appliances → Peripherals merger Phase 4.
#   Removed "export appliance_models contains only device_type 1 records" test
#     — admin_data_transfers no longer handles data_type: "appliance_models".
#   Removed "import appliance_models creates record with device_type appliance" test
#     — device_type: :appliance no longer exists.
#   Fixed "export peripheral_models contains only device_type 2 records":
#     hsc50 (formerly device_type: 1 appliance) is now device_type: 2 (peripheral),
#     so it now correctly appears in the peripheral export. Removed the assertion
#     that said HSC50 must not appear; replaced with assert_includes for HSC50.
# v1.1 (Session 29): Added peripheral_models export and import tests.
# v1.0 (Session 24): New test file.

require "test_helper"
require "csv"

class Admin::DataTransfersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @alice   = owners(:one)   # admin
    @bob     = owners(:two)   # non-admin
    @charlie = owners(:three) # non-admin
  end

  # ── Authentication / authorisation ───────────────────────────────────────

  test "show requires login" do
    get admin_data_transfer_path
    assert_response :redirect
  end

  test "show requires admin — non-admin is redirected" do
    login_as(@bob)
    get admin_data_transfer_path
    assert_response :redirect
  end

  test "export requires login" do
    get admin_export_data_transfer_path, params: { data_type: "computer_models" }
    assert_response :redirect
  end

  test "export requires admin" do
    login_as(@bob)
    get admin_export_data_transfer_path, params: { data_type: "computer_models" }
    assert_response :redirect
  end

  test "import requires login" do
    post admin_import_data_transfer_path, params: { data_type: "component_types" }
    assert_response :redirect
  end

  test "import requires admin" do
    login_as(@bob)
    post admin_import_data_transfer_path, params: { data_type: "component_types" }
    assert_response :redirect
  end

  # ── show ─────────────────────────────────────────────────────────────────

  test "show renders successfully for admin" do
    login_as(@alice)
    get admin_data_transfer_path
    assert_response :ok
  end

  # ── export — computer_models ──────────────────────────────────────────────

  test "export computer_models returns CSV attachment" do
    login_as(@alice)
    get admin_export_data_transfer_path, params: { data_type: "computer_models" }

    assert_response :ok
    assert_equal "text/csv; charset=utf-8", response.content_type
    assert_match "attachment", response.headers["Content-Disposition"]
  end

  test "export computer_models CSV has correct header" do
    login_as(@alice)
    get admin_export_data_transfer_path, params: { data_type: "computer_models" }

    csv = CSV.parse(response.body, headers: true)
    assert_equal ComputerModelExportService::CSV_HEADERS, csv.headers
  end

  test "export computer_models filename contains date and type" do
    login_as(@alice)
    get admin_export_data_transfer_path, params: { data_type: "computer_models" }

    disposition = response.headers["Content-Disposition"]
    assert_match "computer_models", disposition
    assert_match Date.today.to_s,   disposition
    assert_match ".csv",            disposition
  end

  test "export computer_models contains only device_type 0 records" do
    login_as(@alice)
    get admin_export_data_transfer_path, params: { data_type: "computer_models" }

    csv   = CSV.parse(response.body, headers: true)
    names = csv.map { |row| row["name"] }

    assert_includes names, "PDP-11/70"
    # hsc50 is now device_type: 2 (peripheral) — must not appear in computer export
    refute_includes names, "HSC50"
  end

  # ── export — peripheral_models ────────────────────────────────────────────

  test "export peripheral_models returns CSV attachment with correct header" do
    ComputerModel.create!(name: "LA120", device_type: :peripheral)

    login_as(@alice)
    get admin_export_data_transfer_path, params: { data_type: "peripheral_models" }

    assert_response :ok
    assert_equal "text/csv; charset=utf-8", response.content_type
    csv = CSV.parse(response.body, headers: true)
    assert_equal ComputerModelExportService::CSV_HEADERS, csv.headers
  end

  test "export peripheral_models filename contains date and type" do
    login_as(@alice)
    get admin_export_data_transfer_path, params: { data_type: "peripheral_models" }

    disposition = response.headers["Content-Disposition"]
    assert_match "peripheral_models", disposition
    assert_match Date.today.to_s,     disposition
    assert_match ".csv",              disposition
  end

  test "export peripheral_models contains only device_type 2 records" do
    # Create a peripheral model to assert against in addition to the fixtures.
    ComputerModel.create!(name: "LA120", device_type: :peripheral)

    login_as(@alice)
    get admin_export_data_transfer_path, params: { data_type: "peripheral_models" }

    csv   = CSV.parse(response.body, headers: true)
    names = csv.map { |row| row["name"] }

    assert_includes names, "LA120",   "LA120 (peripheral) must appear in peripheral export"
    # hsc50 is now device_type: 2 (peripheral) after the Session 41 merger —
    # it correctly appears in the peripheral export.
    assert_includes names, "HSC50",   "HSC50 is now a peripheral and must appear in peripheral export"
    refute_includes names, "PDP-11/70", "Computer model must not appear in peripheral export"
  end

  # ── export — component_types ──────────────────────────────────────────────

  test "export component_types returns CSV with correct header" do
    login_as(@alice)
    get admin_export_data_transfer_path, params: { data_type: "component_types" }

    assert_response :ok
    csv = CSV.parse(response.body, headers: true)
    assert_equal ComponentTypeExportService::CSV_HEADERS, csv.headers
  end

  test "export component_types includes fixture records" do
    login_as(@alice)
    get admin_export_data_transfer_path, params: { data_type: "component_types" }

    csv   = CSV.parse(response.body, headers: true)
    names = csv.map { |row| row["name"] }
    assert_includes names, "Memory Board"
    assert_includes names, "CPU Board"
  end

  # ── export — owner_collection (specific owner) ────────────────────────────

  test "export owner_collection for specific owner returns CSV with correct headers" do
    login_as(@alice)
    get admin_export_data_transfer_path,
        params: { data_type: "owner_collection", owner_id: @alice.id }

    assert_response :ok
    csv = CSV.parse(response.body, headers: true)
    assert_equal OwnerExportService::CSV_HEADERS, csv.headers
  end

  test "export owner_collection filename contains owner user_name and date" do
    login_as(@alice)
    get admin_export_data_transfer_path,
        params: { data_type: "owner_collection", owner_id: @alice.id }

    disposition = response.headers["Content-Disposition"]
    assert_match "alice",          disposition
    assert_match Date.today.to_s,  disposition
  end

  # ── export — owner_collection (all owners) ────────────────────────────────

  test "export owner_collection all owners returns CSV with owner_user_name header" do
    login_as(@alice)
    get admin_export_data_transfer_path,
        params: { data_type: "owner_collection", owner_id: "all" }

    assert_response :ok
    csv = CSV.parse(response.body, headers: true)
    assert_equal AllOwnersExportService::CSV_HEADERS, csv.headers
  end

  test "export owner_collection all owners filename contains all_owners and date" do
    login_as(@alice)
    get admin_export_data_transfer_path,
        params: { data_type: "owner_collection", owner_id: "all" }

    disposition = response.headers["Content-Disposition"]
    assert_match "all_owners",    disposition
    assert_match Date.today.to_s, disposition
  end

  # ── export — validation failures ─────────────────────────────────────────

  test "export without data_type redirects with alert" do
    login_as(@alice)
    get admin_export_data_transfer_path

    assert_redirected_to admin_data_transfer_path
    assert_match "select a data type", flash[:alert]
  end

  test "export owner_collection without owner_id redirects with alert" do
    login_as(@alice)
    get admin_export_data_transfer_path, params: { data_type: "owner_collection" }

    assert_redirected_to admin_data_transfer_path
    assert_match "select an owner", flash[:alert]
  end

  # ── import — missing file ─────────────────────────────────────────────────

  test "import with no file redirects with alert" do
    login_as(@alice)
    post admin_import_data_transfer_path, params: { data_type: "computer_models" }

    assert_redirected_to admin_data_transfer_path
    assert_match "select a CSV file", flash[:alert]
  end

  test "import without data_type redirects with alert" do
    login_as(@alice)
    post admin_import_data_transfer_path,
         params: { file: csv_upload("name\nPDP-11/44\n") }

    assert_redirected_to admin_data_transfer_path
    assert_match "select a data type", flash[:alert]
  end

  # ── import — computer_models ──────────────────────────────────────────────

  test "import computer_models creates new record and shows success notice" do
    login_as(@alice)
    csv_content = "name\nPDP-11/44\n"

    assert_difference "ComputerModel.count", 1 do
      post admin_import_data_transfer_path,
           params: { data_type: "computer_models", file: csv_upload(csv_content) }
    end

    assert_redirected_to admin_data_transfer_path
    assert_match "computer model",  flash[:notice]
    assert_match "1",               flash[:notice]

    model = ComputerModel.find_by!(name: "PDP-11/44")
    assert model.device_type_computer?
  end

  test "import computer_models skips existing records silently" do
    login_as(@alice)
    csv_content = "name\nPDP-11/70\n"

    assert_no_difference "ComputerModel.count" do
      post admin_import_data_transfer_path,
           params: { data_type: "computer_models", file: csv_upload(csv_content) }
    end

    assert_redirected_to admin_data_transfer_path
    assert_match "0",               flash[:notice]
    assert_nil flash[:alert]
  end

  # ── import — peripheral_models ────────────────────────────────────────────

  test "import peripheral_models creates record with device_type peripheral" do
    login_as(@alice)
    csv_content = "name\nLA120\n"

    assert_difference "ComputerModel.count", 1 do
      post admin_import_data_transfer_path,
           params: { data_type: "peripheral_models", file: csv_upload(csv_content) }
    end

    assert_redirected_to admin_data_transfer_path
    assert_match "peripheral model", flash[:notice]
    assert_match "1",                flash[:notice]

    model = ComputerModel.find_by!(name: "LA120")
    assert model.device_type_peripheral?
  end

  test "import peripheral_models skips existing records silently" do
    existing = ComputerModel.create!(name: "LA120", device_type: :peripheral)
    login_as(@alice)

    assert_no_difference "ComputerModel.count" do
      post admin_import_data_transfer_path,
           params: { data_type: "peripheral_models", file: csv_upload("name\nLA120\n") }
    end

    assert_nil flash[:alert]
  end

  # ── import — component_types ──────────────────────────────────────────────

  test "import component_types creates new record and shows success notice" do
    login_as(@alice)
    csv_content = "name\nNetwork Interface\n"

    assert_difference "ComponentType.count", 1 do
      post admin_import_data_transfer_path,
           params: { data_type: "component_types", file: csv_upload(csv_content) }
    end

    assert_redirected_to admin_data_transfer_path
    assert_match "component type", flash[:notice]
    assert_match "1",              flash[:notice]
  end

  test "import component_types skips existing records silently" do
    login_as(@alice)
    csv_content = "name\nMemory Board\n"

    assert_no_difference "ComponentType.count" do
      post admin_import_data_transfer_path,
           params: { data_type: "component_types", file: csv_upload(csv_content) }
    end

    assert_nil flash[:alert]
  end

  # ── import — owner_collection ─────────────────────────────────────────────

  test "import owner_collection for specific owner creates records" do
    login_as(@alice)

    csv_content = CSV.generate(headers: true, force_quotes: true) do |csv|
      csv << OwnerExportService::CSV_HEADERS
      csv << ["computer", "PDP-11/70", nil, "ADMIN-IMPORT-SN-01",
              nil, nil, nil, nil, nil, nil, nil, nil]
    end

    assert_difference "Computer.count", 1 do
      post admin_import_data_transfer_path,
           params: { data_type: "owner_collection", owner_id: @charlie.id,
                     file: csv_upload(csv_content) }
    end

    assert_redirected_to admin_data_transfer_path
    assert_match "computer", flash[:notice]

    computer = Computer.find_by!(serial_number: "ADMIN-IMPORT-SN-01")
    assert_equal @charlie, computer.owner
  end

  test "import owner_collection without owner_id redirects with alert" do
    login_as(@alice)
    csv_content = "record_type,computer_model\ncomputer,PDP-11/70\n"

    post admin_import_data_transfer_path,
         params: { data_type: "owner_collection", file: csv_upload(csv_content) }

    assert_redirected_to admin_data_transfer_path
    assert_match "select an owner", flash[:alert]
  end

  # ── import — service errors ───────────────────────────────────────────────

  test "import computer_models with missing name column shows alert" do
    login_as(@alice)
    csv_content = "model_name\nPDP-11/44\n"

    assert_no_difference "ComputerModel.count" do
      post admin_import_data_transfer_path,
           params: { data_type: "computer_models", file: csv_upload(csv_content) }
    end

    assert_redirected_to admin_data_transfer_path
    assert_match "Import failed", flash[:alert]
  end

  private

  def csv_upload(content, filename: "admin_import_test.csv", content_type: "text/csv")
    tempfile = Tempfile.new(["admin_import_test", ".csv"])
    tempfile.write(content)
    tempfile.rewind
    tempfile.close

    Rack::Test::UploadedFile.new(tempfile.path, content_type, false,
                                  original_filename: filename)
  end
end
