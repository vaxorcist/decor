# decor/app/controllers/software_items_controller.rb
# version 1.5
# v1.5 (Session 88, Storage Locations feature Session E — see
#   DECOR_PROJECT.md "Storage Locations Feature — Session Plan"): Added the
#   Storage Location filter to the index action, mirroring
#   ComputersController#index v1.25 exactly:
#     if logged_in? && params[:storage_location_id].present?
#       if Current.owner.storage_locations.exists?(id: params[:storage_location_id])
#         scope = scope.where(storage_location_id: params[:storage_location_id])
#       end
#     end
#   Same two deliberate guards as the Computers precedent, both required by
#   the confirmed privacy design (storage locations are private per-owner
#   data — Session D privacy audit passed with no code changes needed):
#     1. `if logged_in?` — mirrors the existing barter_status guard exactly;
#        logged-out visitors get no storage-location filtering at all.
#     2. The `Current.owner.storage_locations.exists?(id: ...)` check — the
#        filter dropdown (SoftwareItemsHelper#software_item_filter_storage_locations_options)
#        only ever offers Current.owner's OWN storage locations, so a
#        legitimate request can never submit another owner's id. But a
#        crafted URL param COULD try one anyway. Without this guard, a
#        `WHERE storage_location_id = X` filter would still silently work
#        for any X — letting a logged-in user enumerate which software items
#        share a storage_location_id belonging to a DIFFERENT owner, even
#        without ever seeing that owner's location name. Silently ignoring
#        an unowned id (falling through to "no storage-location filter
#        applied" rather than raising or trusting the raw param) closes
#        that probe without adding any new visible error state.
#   Positioned after the barter status filter block, before Sort — same
#   ordering as ComputersController#index and ComponentsController#index.
# v1.4 (Session 81, gap-closing follow-up): Storage Locations feature
#   Session C. Added :storage_location_id to software_item_params — a
#   flagged Session C gap (the dropdown shipped in _form.html.erb v1.2 the
#   same session this permit was needed, but the permit itself was
#   missed, same shape as the identical fix on the other two controllers).
# v1.3 (Session 50): Added search, sort, and filter logic to index action.
#   - Search: params[:query] — LIKE match against software name, version, description.
#   - Sort: params[:sort] — 6 options; default is name_asc_version_asc.
#   - Filter by software name: params[:software_name_id].
#   - Filter by owner: params[:owner_id].
#   - Barter status filter: params[:barter_status] — logged-in users only;
#     default "0+1" (no_barter + offered), matching ComponentsController pattern.
#   - @index_path now preserves current filter/sort params so turbo stream
#     load-more pagination passes them through correctly.
#
# v1.2 (Session 48): Software feature Session F — public index action.
# v1.1 (Session 46): Software feature Session D — owner-facing CRUD.
# v1.0 (Session 45): Software feature Session C — read-only actions.

class SoftwareItemsController < ApplicationController
  # set_software_item only for actions that have an :id param.
  # index, new, and create build from scope/Current.owner instead.
  before_action :set_software_item, only: %i[show edit update destroy]

  # Mutating actions require a logged-in session.
  # index and show are intentionally excluded — publicly accessible.
  before_action :require_login, only: %i[new create edit update destroy]

  # Ownership guard for edit/update/destroy — delegates to require_owner.
  # new and create are implicitly scoped to Current.owner (no ownership check needed).
  before_action :ensure_software_item_belongs_to_current_owner, only: %i[edit update destroy]

  # GET /software_items
  # Publicly accessible. All software items across all owners, paginated.
  # eager_load produces LEFT OUTER JOINs for all associations, which are required
  # for multi-table ORDER BY (Arel.sql) and WHERE clauses on joined table columns
  # (search, software_name_id filter, owner_id filter).
  def index
    scope = SoftwareItem
              .eager_load(:software_name, :software_condition, :owner,
                          computer: :computer_model)

    # ── Search ────────────────────────────────────────────────────────────────
    # Searches across software name (joined), version, and description.
    # LIKE is case-insensitive in SQLite for ASCII characters.
    # Users may use % (any chars) or _ (single char) as wildcards — note displayed
    # in the filter partial.
    if params[:query].present?
      q = "%#{params[:query]}%"
      scope = scope.where(
        "software_names.name LIKE :q OR software_items.version LIKE :q OR software_items.description LIKE :q",
        q: q
      )
    end

    # ── Filter by software name ───────────────────────────────────────────────
    if params[:software_name_id].present?
      scope = scope.where(software_name_id: params[:software_name_id])
    end

    # ── Filter by owner ───────────────────────────────────────────────────────
    if params[:owner_id].present?
      scope = scope.where(owner_id: params[:owner_id])
    end

    # ── Barter status filter (logged-in members only) ─────────────────────────
    # Non-logged-in visitors see all items with no barter information displayed.
    # Default for logged-in users: "0+1" (no_barter + offered). This hides "wanted"
    # items from the default listing — consistent with ComponentsController.
    if logged_in?
      barter_filter = params[:barter_status].presence || "0+1"
      scope = case barter_filter
      when "0"   then scope.where(barter_status: 0)
      when "1"   then scope.where(barter_status: 1)
      when "2"   then scope.where(barter_status: 2)
      else            scope.where(barter_status: [0, 1])  # "0+1" and any unknown value
      end
    end

    # ── Storage Location filter (logged-in members only) ──────────────────────
    # Only honors a storage_location_id that actually belongs to Current.owner.
    # Mirrors ComputersController#index v1.25 exactly — see the header comment
    # above (Session E) for the full rationale on both guards.
    if logged_in? && params[:storage_location_id].present?
      if Current.owner.storage_locations.exists?(id: params[:storage_location_id])
        scope = scope.where(storage_location_id: params[:storage_location_id])
      end
    end

    # ── Sort ──────────────────────────────────────────────────────────────────
    # Multi-table ORDER BY references (software_names.name, owners.user_name) require
    # Arel.sql() because Rails rejects bare strings containing dots or SQL keywords.
    # NULLS LAST on version so items with no version sort after those that have one.
    scope = case params[:sort]
    when "added_desc"
      scope.order(created_at: :desc)
    when "added_asc"
      scope.order(created_at: :asc)
    when "name_desc_version_asc"
      scope.order(Arel.sql("software_names.name DESC, software_items.version ASC NULLS LAST"))
    when "owner_asc_name_asc_version_asc"
      scope.order(Arel.sql("owners.user_name ASC, software_names.name ASC, software_items.version ASC NULLS LAST"))
    when "owner_asc_name_desc_version_asc"
      scope.order(Arel.sql("owners.user_name ASC, software_names.name DESC, software_items.version ASC NULLS LAST"))
    else
      # Default: Software (A-Z) and Version (A-Z) — covers "name_asc_version_asc"
      # param and any unknown/missing value.
      scope.order(Arel.sql("software_names.name ASC, software_items.version ASC NULLS LAST"))
    end

    # paginate sets @page as a side effect via set_page_and_extract_portion_from.
    # Must NOT be assigned — see RAILS_SPECIFICS.md "paginate — NEVER assign".
    paginate scope

    @page_title     = "Software"
    @turbo_tbody_id = "software_items"
    @load_more_id   = "load_more_software_items"

    # Preserve all active filter/sort params in @index_path so that turbo stream
    # load-more requests carry them through. Exclude :page — load_more adds the
    # next page number itself.
    @index_path = software_items_path(request.query_parameters.except("page"))
  end

  # GET /software_items/:id
  # Publicly accessible detail page for a single software item.
  def show
  end

  # GET /software_items/new
  # New software item form scoped to the current owner.
  def new
    @software_item = Current.owner.software_items.new
  end

  # POST /software_items
  # Creates a new software item for the current owner.
  # add_another param: submitting "Create and add another" redirects back to the
  # new form instead of the item's show page.
  def create
    @software_item = Current.owner.software_items.build(software_item_params)

    if @software_item.save
      if params[:add_another]
        redirect_to new_software_item_path, notice: "Software item was successfully created. Add another!"
      else
        redirect_to software_item_path(@software_item), notice: "Software item was successfully created."
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /software_items/:id/edit
  def edit
  end

  # PATCH/PUT /software_items/:id
  # Updates the software item and redirects to its show page on success.
  def update
    if @software_item.update(software_item_params)
      redirect_to software_item_path(@software_item), notice: "Software item was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /software_items/:id
  # Captures the owner before destroy so we can redirect to their software sub-page
  # even after the record is gone.
  def destroy
    owner = @software_item.owner
    @software_item.destroy
    redirect_to software_owner_path(owner), notice: "Software item was successfully deleted."
  end

  private

  # Eager-loads all associations accessed by the show/edit views in a single query.
  def set_software_item
    @software_item = SoftwareItem
                       .eager_load(:software_name, :software_condition,
                                   :owner, computer: :computer_model)
                       .find(params[:id])
  end

  # Delegates to require_owner (defined in the authentication concern).
  def ensure_software_item_belongs_to_current_owner
    require_owner(@software_item.owner)
  end

  # Strong parameters for create and update.
  def software_item_params
    params.require(:software_item).permit(
      :software_name_id,
      :software_condition_id,
      :computer_id,
      :version,
      :description,
      :history,
      :barter_status,
      :storage_location_id  # Storage Locations feature Session C — flagged
      # gap, closed as a follow-up. Without this permit,
      # the dropdown added to _form.html.erb v1.2 the
      # same session silently no-ops on save.
    )
  end
end
