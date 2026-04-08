# decor/app/controllers/admin/data_transfers_controller.rb
# version 1.3
# v1.3 (Session 48): Updated build_success_message and import action for partial success.
#   Added connection_group_count and software_item_count to the owner_collection
#   success message — both were silently omitted in v1.2.
#   Added row_errors and row_warnings handling: when OwnerImportService returns
#   partial success (success: true but row_errors present), flash[:notice] shows
#   the saved-record counts and flash[:row_errors] / flash[:row_warnings] carry
#   the per-row detail for display in the view.
#   Updated atomicity message in import notes — removed the "all or nothing" claim
#   since OwnerImportService v1.8 saves each row independently.
#
# v1.2 (Session 41): Appliances → Peripherals merger Phase 4.
# v1.1 (Session 29): Added peripheral_models data_type.

require "csv"

module Admin
  class DataTransfersController < BaseController
    before_action :load_owners, only: [:show]

    def show
    end

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
        flash[:notice]        = build_success_message(data_type, result)
        # Partial success: carry per-row issues to the view via flash.
        # flash[:row_errors]   — rows that were skipped (not saved)
        # flash[:row_warnings] — rows that were saved with a caveat
        flash[:row_errors]    = result[:row_errors]   if result[:row_errors]&.any?
        flash[:row_warnings]  = result[:row_warnings] if result[:row_warnings]&.any?
      else
        flash[:alert] = "Import failed: #{result[:error]}"
      end

      redirect_to admin_data_transfer_path
    end

    private

    def load_owners
      @owners = Owner.order(:user_name)
    end

    # ── Export helpers ────────────────────────────────────────────────────────

    def build_export(data_type, owner_id)
      case data_type
      when "computer_models"
        csv      = ComputerModelExportService.export(device_type: :computer)
        filename = "computer_models_#{Date.today}.csv"

      when "peripheral_models"
        csv      = ComputerModelExportService.export(device_type: :peripheral)
        filename = "peripheral_models_#{Date.today}.csv"

      when "component_types"
        csv      = ComponentTypeExportService.export
        filename = "component_types_#{Date.today}.csv"

      when "owner_collection"
        if owner_id == "all"
          csv      = AllOwnersExportService.export
          filename = "all_owners_#{Date.today}.csv"
        elsif owner_id.present?
          owner = Owner.find_by(id: owner_id)
          return [nil, nil] unless owner

          csv      = OwnerExportService.export(owner)
          filename = "decor_export_#{owner.user_name}_#{Date.today}.csv"
        else
          return [nil, nil]
        end

      else
        return [nil, nil]
      end

      [csv, filename]
    end

    def export_validation_error(data_type, owner_id)
      if data_type == "owner_collection" && owner_id.blank?
        "Please select an owner (or All Owners) when exporting Owner Collection Data."
      else
        "Unknown data type. Please select a valid option."
      end
    end

    # ── Import helpers ────────────────────────────────────────────────────────

    def process_import(data_type, owner_id, file)
      case data_type
      when "computer_models"
        ComputerModelImportService.process(file, device_type: :computer)

      when "peripheral_models"
        ComputerModelImportService.process(file, device_type: :peripheral)

      when "component_types"
        ComponentTypeImportService.process(file)

      when "owner_collection"
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

    # Builds the flash[:notice] message for a successful import.
    # For owner_collection, lists non-zero counts per record type.
    # When some rows were skipped (partial success), the notice still lists what
    # WAS saved; flash[:row_errors] carries the per-row detail separately.
    def build_success_message(data_type, result)
      case data_type
      when "computer_models"
        "Successfully imported #{result[:count]} computer model(s)."
      when "peripheral_models"
        "Successfully imported #{result[:count]} peripheral model(s)."
      when "component_types"
        "Successfully imported #{result[:count]} component type(s)."
      when "owner_collection"
        parts = []
        parts << "#{result[:computer_count]} computer(s)"           if result[:computer_count].to_i         > 0
        parts << "#{result[:peripheral_count]} peripheral(s)"       if result[:peripheral_count].to_i       > 0
        parts << "#{result[:component_count]} component(s)"         if result[:component_count].to_i        > 0
        parts << "#{result[:connection_group_count]} connection(s)"  if result[:connection_group_count].to_i > 0
        parts << "#{result[:software_item_count]} software item(s)"  if result[:software_item_count].to_i   > 0

        skipped = result[:row_errors]&.size.to_i

        if parts.any? && skipped > 0
          "Partially imported — saved #{parts.join(', ')}. " \
          "#{skipped} row(s) could not be imported (see details below)."
        elsif parts.any?
          "Successfully imported #{parts.join(', ')}."
        elsif skipped > 0
          "Import complete — no new records were added. " \
          "#{skipped} row(s) could not be imported (see details below)."
        else
          "Nothing to import — all records already exist."
        end
      else
        "Import complete."
      end
    end
  end
end
