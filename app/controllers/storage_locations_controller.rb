# decor/app/controllers/storage_locations_controller.rb
# version 1.0
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
# delete_confirm / destroy — INTERIM, NOT the final design:
# storage_location.rb v1.0's own header comment says the owner-facing delete
# confirmation "must warn with counts before the destroy happens (see
# Session B)." That warning cannot actually be built yet: StorageLocation has
# no has_many :computers / :components / :software_items association until
# Session C adds the FK columns and those associations (deliberately
# deferred — see storage_location.rb v1.0's own comment on this). Since
# nothing can reference a StorageLocation until Session C ships, there is
# genuinely nothing to count right now. Rather than guess at Session C's
# eventual association/method names, delete_confirm here shows a plain,
# honest "are you sure" with no counts. Session C MUST extend both this
# action and its view to show real affected-record counts once those
# associations exist — flagged explicitly so this isn't mistaken for a
# finished delete flow.
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
  # Plain confirmation only — see the class-level comment above for why no
  # affected-record counts are shown yet (Session C must add them).
  def delete_confirm
  end

  # DELETE /storage_locations/:id
  def destroy
    @storage_location.destroy
    redirect_to storage_locations_path, notice: "Storage location was successfully deleted."
  end

  private

  # Simple find — no eager_load needed, unlike SoftwareItemsController#set_software_item,
  # since StorageLocation has no associations to display yet (Session C adds them).
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
