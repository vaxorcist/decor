# decor/app/controllers/storage_locations_controller.rb
# version 1.1
# v1.1 (Session C, Storage Locations feature, Part 3 of 6): delete_confirm
#   now computes and exposes real affected-record counts, replacing Session
#   B's interim, count-less confirmation. This is possible now because
#   StorageLocation gained has_many :computers/:components/:software_items
#   (dependent: :nullify) this session (storage_location.rb v1.1), once
#   migration 20260803000100 added the storage_location_id FK columns those
#   associations depend on. See storage_location.rb v1.1 and
#   delete_confirm.html.erb v1.1 for the other two halves of this change.
#   Session B's class-level comment (below, preserved for continuity) is
#   now resolved — this note documents the resolution rather than deleting
#   the historical context.
#
# Session B (Storage Locations feature, Part 2 of 6 — see DECOR_PROJECT.md
# "Storage Locations Feature — Session Plan").
#
# Access model — DIFFERENT from SoftwareItemsController's public-index/
# owner-scoped-mutations split. EVERY action here requires login and is
# scoped to Current.owner; there is no public or other-owner-visible view of
# any StorageLocation at all. This matches the Session 79 design
# consultation's confirmed answer: "Private from other owners AND visitors;
# ... NO dedicated admin browsing UI."
#
# No :show action (see routes.rb v3.8) — a StorageLocation carries only a
# `name` (storage_location.rb v1.0), so the index list itself is the only
# display surface needed; edit is reached directly from the index row.
#
# delete_confirm / destroy — RESOLVED Session C (see v1.1 note above).
# Session B's original comment here explained that storage_location.rb
# v1.0's own header comment called for the delete confirmation to "warn
# with counts before the destroy happens," but that nothing could be
# counted yet because the has_many associations didn't exist until Session
# C. That gap is now closed.
class StorageLocationsController < ApplicationController
  before_action :require_login
  before_action :set_storage_location, only: %i[edit update destroy delete_confirm]
  before_action :ensure_storage_location_belongs_to_current_owner,
                only: %i[edit update destroy delete_confirm]

  # GET /storage_locations
  # Always Current.owner's own records — never another owner's, and never
  # exposed to logged-out visitors (require_login above covers that).
  def index
    @storage_locations = Current.owner.storage_locations.order(:name)
  end

  # GET /storage_locations/new
  def new
    @storage_location = Current.owner.storage_locations.new
  end

  # POST /storage_locations
  def create
    @storage_location = Current.owner.storage_locations.build(storage_location_params)

    if @storage_location.save
      redirect_to storage_locations_path, notice: "Storage location was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /storage_locations/:id/edit
  def edit
  end

  # PATCH/PUT /storage_locations/:id
  def update
    if @storage_location.update(storage_location_params)
      redirect_to storage_locations_path, notice: "Storage location was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # GET /storage_locations/:id/delete_confirm
  # Session C: computes the real affected-record counts the delete_confirm
  # view warns with. Simple .count calls — this owner's own storage
  # location list is expected to stay small (per Session B's rationale for
  # skipping pagination), and each count is a single indexed COUNT(*) query
  # against storage_location_id (migration 20260803000100 added the index).
  def delete_confirm
    @computers_count      = @storage_location.computers.count
    @components_count     = @storage_location.components.count
    @software_items_count = @storage_location.software_items.count
  end

  # DELETE /storage_locations/:id
  # StorageLocation's has_many :nullify associations (storage_location.rb
  # v1.1) handle clearing storage_location_id on every referencing
  # Computer/Component/SoftwareItem automatically — no explicit nullify
  # code needed here.
  def destroy
    @storage_location.destroy
    redirect_to storage_locations_path, notice: "Storage location was successfully deleted."
  end

  private

  # Simple find — no eager_load needed. The delete_confirm counts above are
  # cheap, separate COUNT queries rather than a single eager-loaded fetch,
  # since we only need counts, not the actual associated records.
  def set_storage_location
    @storage_location = StorageLocation.find(params[:id])
  end

  # Delegates to require_owner (Authentication concern) — same pattern as
  # SoftwareItemsController#ensure_software_item_belongs_to_current_owner.
  def ensure_storage_location_belongs_to_current_owner
    require_owner(@storage_location.owner)
  end

  # Strong parameters for create and update. Only :name exists on this model
  # (storage_location.rb v1.0) — Session C's belongs_to additions live on the
  # OTHER side (Computer/Component/SoftwareItem forms), not here.
  def storage_location_params
    params.require(:storage_location).permit(:name)
  end
end
