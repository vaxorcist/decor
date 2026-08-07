# decor/app/controllers/storage_locations_controller.rb
# version 1.3
# v1.3 (Session 91, ad-hoc follow-up to Session 90): Reworked the `show`
#   action per Ulli's feedback that the flat, alphabetical-by-name list
#   (Session 90) wasn't enough to identify an item. Replaced
#   build_storage_location_items (single flat array, one :name/:kind/:path
#   hash shape for all types) with four separate, category-grouped builder
#   methods:
#     build_computer_rows(scope)   — used for BOTH Computers and
#       Peripherals (same device_type enum, same table, same field set —
#       only the scope differs), returns Computer Model/Peripheral Model,
#       DEC Part Number (order_number), DEC Serial Number (serial_number),
#       Owner Part Number (owner_part_number), and the link path.
#     build_component_rows(scope)  — Component Type, DEC Part Number, DEC
#       Serial Number, Owner Part Number, link path.
#     build_software_rows(scope)   — Software Name, Version, link path.
#   Each is sorted case-insensitively by its own primary display name
#   (computer_model.name / component_type.name / software_name.name) —
#   this is the "Model/Type/Software" sort Ulli asked for. Overall order
#   is now fixed by category (Computers, Peripherals, Components,
#   Software) rather than interleaved alphabetically across types.
#   @computer_rows/@peripheral_rows split from the single Computer
#   association via the device_type enum's generated `device_type_computer`
#   / `device_type_peripheral` scopes (enum :device_type, prefix: true —
#   see computer.rb) — NOT two separate associations; StorageLocation only
#   has one has_many :computers covering both device types (storage_location.rb
#   v1.1).
#   Field names/associations verified against the actual uploaded model
#   files before writing this (Pre-Implementation Verification) — not
#   guessed: Computer#computer_model/#order_number/#serial_number/
#   #owner_part_number, Component#component_type/#order_number/
#   #serial_number/#owner_part_number, SoftwareItem#software_name/#version.
#   Access model, before_action scoping, and every other action
#   (index/new/create/edit/update/delete_confirm/destroy) UNCHANGED from
#   v1.2 — only the `show` action and its private builder methods changed.
#
# v1.2 (Session 90): Added the `show` action — Ulli asked for a page
#   listing everything stored at a location (Computers, Peripherals,
#   Components, Software Items combined, regardless of category), linked
#   from the location's name on the index page. Reverses Session B's
#   original "no :show action needed" decision (see the v1.1/Session B
#   notes below, kept for historical context) — that decision predates
#   Session C's has_many :computers/:components/:software_items
#   associations, which make this straightforward now.
#   Access model UNCHANGED from every other action here: :show added to
#   both before_action scoping lists (set_storage_location,
#   ensure_storage_location_belongs_to_current_owner) — private,
#   Current.owner-only, no admin exception (unlike computers#show, which is
#   public).
#
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
class StorageLocationsController < ApplicationController
  before_action :require_login
  before_action :set_storage_location, only: %i[show edit update destroy delete_confirm]
  before_action :ensure_storage_location_belongs_to_current_owner,
                only: %i[show edit update destroy delete_confirm]

  # GET /storage_locations
  # Always Current.owner's own records — never another owner's, and never
  # exposed to logged-out visitors (require_login above covers that).
  def index
    @storage_locations = Current.owner.storage_locations.order(:name)
  end

  # GET /storage_locations/:id
  # Session 91 (reworked from Session 90's single flat list). Lists
  # everything currently assigned to this storage location, grouped into
  # four fixed categories — Computers, Peripherals, Components, Software —
  # each internally sorted case-insensitively by its own Model/Type/
  # Software Name. Private/owner-only, same as every other action on this
  # controller — no admin exception.
  def show
    computers = @storage_location.computers.includes(:computer_model)

    @computer_rows   = build_computer_rows(computers.device_type_computer)
    @peripheral_rows = build_computer_rows(computers.device_type_peripheral)
    @component_rows  = build_component_rows(@storage_location.components.includes(:component_type))
    @software_rows   = build_software_rows(@storage_location.software_items.includes(:software_name))
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

  # Session 91. Builds one row per Computer (or Peripheral — same table,
  # same field set, distinguished only by which device_type-scoped relation
  # is passed in) with the full identifying-field set Ulli asked for:
  # Computer/Peripheral Model, DEC Part Number (order_number), DEC Serial
  # Number (serial_number), Owner Part Number (owner_part_number). Sorted
  # case-insensitively by Model name — the "then by Model" part of Ulli's
  # sort request. Link target matches the established convention
  # (computers/show.html.erb's own <h1>, and its Components/Software
  # sub-tables): computer_path.
  def build_computer_rows(scope)
    scope.map do |computer|
      {
        model_name:        computer.computer_model.name,
        order_number:      computer.order_number,
        serial_number:     computer.serial_number,
        owner_part_number: computer.owner_part_number,
        path:              computer_path(computer)
      }
    end.sort_by { |row| row[:model_name].downcase }
  end

  # Session 91. Builds one row per Component with Component Type, DEC Part
  # Number, DEC Serial Number, Owner Part Number. Sorted case-insensitively
  # by Component Type name. Link target matches
  # computers/show.html.erb's Components sub-table: component_path.
  def build_component_rows(scope)
    scope.map do |component|
      {
        type_name:         component.component_type.name,
        order_number:      component.order_number,
        serial_number:     component.serial_number,
        owner_part_number: component.owner_part_number,
        path:              component_path(component)
      }
    end.sort_by { |row| row[:type_name].downcase }
  end

  # Session 91. Builds one row per Software Item with Software Name and
  # Version only — Software Items have no DEC Part Number/DEC Serial
  # Number/Owner Part Number fields (see software_item.rb — no such
  # columns exist on this model). Sorted case-insensitively by Software
  # Name. Link target matches computers/show.html.erb's Software
  # sub-table: software_item_path.
  def build_software_rows(scope)
    scope.map do |software_item|
      {
        name:    software_item.software_name.name,
        version: software_item.version,
        path:    software_item_path(software_item)
      }
    end.sort_by { |row| row[:name].downcase }
  end
end
