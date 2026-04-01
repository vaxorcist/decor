# decor/app/controllers/admin/software_names_controller.rb
# version 1.0
# Admin CRUD for the software_names lookup table.
#
# SoftwareName is the canonical title of a piece of software (e.g. "WordStar",
# "RT-11"). It is admin-managed and analogous to ComponentType.
#
# Destroy guard: SoftwareName uses dependent: :restrict_with_error, so destroy
# returns false when software_items still reference this record. We redirect with
# an alert in that case (same pattern as ComponentConditionsController).
#
# Strong params include both :name and :description — both are validated at the
# model level (:name required + unique + max 40; :description optional + max 100).

module Admin
  class SoftwareNamesController < BaseController
    before_action :set_software_name, only: %i[edit update destroy]

    # GET /admin/software_names
    # Eager-load software_items to avoid N+1 on the count column.
    def index
      @software_names = SoftwareName.order(:name).includes(:software_items)
    end

    # GET /admin/software_names/new
    def new
      @software_name = SoftwareName.new
    end

    # POST /admin/software_names
    def create
      @software_name = SoftwareName.new(software_name_params)

      if @software_name.save
        redirect_to admin_software_names_path, notice: "Software name was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    # GET /admin/software_names/:id/edit
    def edit
    end

    # PATCH/PUT /admin/software_names/:id
    def update
      if @software_name.update(software_name_params)
        redirect_to admin_software_names_path, notice: "Software name was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /admin/software_names/:id
    # destroy returns false (not raise) when restrict_with_error fires, so we
    # check the return value and show the model's error message as an alert.
    def destroy
      if @software_name.destroy
        redirect_to admin_software_names_path, notice: "Software name was successfully deleted."
      else
        redirect_to admin_software_names_path, alert: @software_name.errors.full_messages.to_sentence
      end
    end

    private

    def set_software_name
      @software_name = SoftwareName.find(params[:id])
    end

    def software_name_params
      params.require(:software_name).permit(:name, :description)
    end
  end
end
