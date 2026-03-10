# decor/app/controllers/admin/data_transfers_controller.rb
# version 1.0
# Session 24: New controller — admin import/export for reference data and owner collections.
#
# Inherits Admin::BaseController which provides:
#   - layout "admin"
#   - before_action :require_admin  (redirects non-admins; non-logged-in redirected by
#     the underlying require_login check)
#
# Supported data types (params[:data_type]):
#   "computer_models"  — ComputerModel records with device_type: computer
#   "appliance_models" — ComputerModel records with device_type: appliance
#   "component_types"  — ComponentType records
#   "owner_collection" — One owner's computers + components via OwnerExportService /
#                        OwnerImportService; or ALL owners via AllOwnersExportService
#
# Actions:
#   show   — renders the selector UI; loads @owners for dropdowns
#   export — GET; reads data_type + owner_id params; responds with CSV download
#   import — POST; reads data_type + owner_id + file params; delegates to service
#
# CSV format for export:
#   computer_models / appliance_models → ComputerModelExportService (headers: name)
#   component_types                    → ComponentTypeExportService  (headers: name)
#   owner_collection (one owner)       → OwnerExportService          (OwnerExportService::CSV_HEADERS)
#   owner_collection (all owners)      → AllOwnersExportService      (owner_user_name + CSV_HEADERS)
#
# Import is always per-owner for owner_collection (owner_id must be a specific owner id).
# "All owners" export exists for admin analysis; there is no corresponding "all owners" import.

require "csv"

module Admin
  class DataTransfersController < BaseController
    # Only the show action needs the owner dropdown populated.
    # export and import redirect on error (new show request re-loads owners).
    before_action :load_owners, only: [:show]

    # show — render the export/import selector page.
    # @owners is populated for the owner dropdowns in both sections.
    def show
    end

    # export — generate a CSV for the selected data type and send it as a download.
    # Uses GET so the browser can trigger a file download directly from a form submit.
    # Redirects with flash[:alert] when data_type or owner_id is missing/invalid.
    def export
      data_type = params[:data_type].presence
      owner_id  = params[:owner_id].presence

      unless data_type.present?
        flash[:alert] = "Please select a data type to export."
        return redirect_to admin_data_transfer_path
      end

      csv, filename = build_export(data_type, owner_id)

      if csv.nil?
        flash[:alert] = export_validation_error(data_type, owner_id)
        return redirect_to admin_data_transfer_path
      end

      send_data csv,
        filename:    filename,
        type:        "text/csv; charset=utf-8",
        disposition: "attachment"
    end

    # import — accept a CSV upload and delegate to the appropriate service.
    # The entire import is atomic (service-level transaction); on any error
    # the transaction rolls back and the admin sees an error flash.
    def import
      data_type = params[:data_type].presence
      owner_id  = params[:owner_id].presence
      file      = params[:file]

      unless data_type.present?
        flash[:alert] = "Please select a data type to import."
        return redirect_to admin_data_transfer_path
      end

      unless file.present?
        flash[:alert] = "Please select a CSV file to import."
        return redirect_to admin_data_transfer_path
      end

      result = process_import(data_type, owner_id, file)

      if result[:success]
        flash[:notice] = build_success_message(data_type, result)
      else
        flash[:alert] = "Import failed: #{result[:error]}"
      end

      redirect_to admin_data_transfer_path
    end

    private

    # ── Before actions ─────────────────────────────────────────────────────

    # Load all owners ordered by user_name for both export and import dropdowns.
    def load_owners
      @owners = Owner.order(:user_name)
    end

    # ── Export helpers ─────────────────────────────────────────────────────

    # Build and return [csv_string, filename] for the given data_type / owner_id.
    # Returns [nil, nil] when validation fails (caller sets appropriate flash).
    def build_export(data_type, owner_id)
      case data_type
      when "computer_models"
        csv      = ComputerModelExportService.export(device_type: :computer)
        filename = "computer_models_#{Date.today}.csv"

      when "appliance_models"
        csv      = ComputerModelExportService.export(device_type: :appliance)
        filename = "appliance_models_#{Date.today}.csv"

      when "component_types"
        csv      = ComponentTypeExportService.export
        filename = "component_types_#{Date.today}.csv"

      when "owner_collection"
        if owner_id == "all"
          # All-owners export: single CSV with owner_user_name prepended.
          # This is an admin-only read export; no corresponding all-owners import.
          csv      = AllOwnersExportService.export
          filename = "all_owners_#{Date.today}.csv"
        elsif owner_id.present?
          owner = Owner.find_by(id: owner_id)
          return [nil, nil] unless owner

          csv      = OwnerExportService.export(owner)
          filename = "decor_export_#{owner.user_name}_#{Date.today}.csv"
        else
          # owner_collection selected but no owner chosen — validation error
          return [nil, nil]
        end

      else
        return [nil, nil]
      end

      [csv, filename]
    end

    # Return a user-facing error message for failed export validation.
    def export_validation_error(data_type, owner_id)
      if data_type == "owner_collection" && owner_id.blank?
        "Please select an owner (or All Owners) when exporting Owner Collection Data."
      else
        "Unknown data type. Please select a valid option."
      end
    end

    # ── Import helpers ──────────────────────────────────────────────────────

    # Dispatch the file to the appropriate import service.
    # Returns a result hash: { success:, count:, error:, computer_count:, component_count: }
    # (exact keys depend on the service; build_success_message reads from result).
    def process_import(data_type, owner_id, file)
      case data_type
      when "computer_models"
        ComputerModelImportService.process(file, device_type: :computer)

      when "appliance_models"
        ComputerModelImportService.process(file, device_type: :appliance)

      when "component_types"
        ComponentTypeImportService.process(file)

      when "owner_collection"
        # Owner must be explicitly selected — no "all owners" import.
        unless owner_id.present?
          return { success: false, error: "Please select an owner to import into." }
        end

        owner = Owner.find_by(id: owner_id)
        unless owner
          return { success: false, error: "Owner not found." }
        end

        OwnerImportService.process(owner, file)

      else
        { success: false, error: "Unknown data type '#{data_type}'." }
      end
    end

    # Build a human-readable success flash message appropriate for each data type.
    def build_success_message(data_type, result)
      case data_type
      when "computer_models"
        "Successfully imported #{result[:count]} computer model(s)."
      when "appliance_models"
        "Successfully imported #{result[:count]} appliance model(s)."
      when "component_types"
        "Successfully imported #{result[:count]} component type(s)."
      when "owner_collection"
        "Successfully imported #{result[:computer_count]} computer(s) " \
        "and #{result[:component_count]} component(s)."
      else
        "Import complete."
      end
    end
  end
end
