# decor/app/controllers/software_items_controller.rb
# version 1.2
# v1.2 (Session 48): Software feature Session F — public index action.
#   Added index: all software items across all owners, publicly accessible,
#   paginated with geared_pagination. Ordered by software name ASC then
#   owner user_name ASC (multi-table ORDER BY requires Arel.sql()).
#   eager_load used (not includes) so the LEFT OUTER JOIN is present for
#   the ORDER BY on joined table columns.
#
# v1.1 (Session 46): Software feature Session D — owner-facing CRUD.
#   Added new, create, edit, update, destroy actions.
#   Added require_login guard for all mutating actions (new/create/edit/update/destroy).
#   Added ensure_software_item_belongs_to_current_owner guard for edit/update/destroy.
#   Scoped set_software_item to only: %i[show edit update destroy] — v1.0 ran it for
#   ALL actions which would crash on new/create (no :id param).
#   Added software_item_params strong-params method.
#
# v1.0 (Session 45): Software feature Session C — read-only actions.
#   show action only; create/edit/update/destroy will be added in Session D.
#
#   Access model:
#     index             — publicly accessible (no login required)
#     show              — publicly accessible (no login required)
#     new/create        — require_login; scoped to Current.owner
#     edit/update       — require_login + must own the record
#     destroy           — require_login + must own the record
#
#   Redirect after destroy: always goes to the owner's software sub-page, since the
#   destroyed record can no longer be shown.

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
  # Ordered by software name (joined), then owner user_name (joined) as tiebreaker.
  # Arel.sql() is required because the ORDER BY references joined table columns
  # (software_names.name and owners.user_name). See RAILS_SPECIFICS.md.
  # eager_load produces a LEFT OUTER JOIN so those columns are available for sorting.
  def index
    scope = SoftwareItem
              .eager_load(:software_name, :software_condition, :owner,
                          computer: :computer_model)
              .order(Arel.sql("software_names.name ASC, owners.user_name ASC"))

    # paginate sets @page as a side effect via set_page_and_extract_portion_from.
    # Must NOT be assigned — assigning overwrites @page with respond_to's return value (nil).
    # Pattern confirmed from computers_controller.rb: `paginate computers` (no assignment).
    paginate scope
    @page_title     = "Software"
    @turbo_tbody_id = "software_items"
    @load_more_id   = "load_more_software_items"
    @index_path     = software_items_path
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
  # :software_name and :software_condition are always joined.
  # computer: :computer_model is left-joined (nullable computer_id).
  # :owner is joined for the "back to owner" link and ownership checks.
  def set_software_item
    @software_item = SoftwareItem
                       .eager_load(:software_name, :software_condition,
                                   :owner, computer: :computer_model)
                       .find(params[:id])
  end

  # Delegates to require_owner (defined in the authentication concern).
  # If the current owner does not match the record's owner, require_owner
  # redirects appropriately (same behaviour as ComponentsController).
  def ensure_software_item_belongs_to_current_owner
    require_owner(@software_item.owner)
  end

  # Strong parameters for create and update.
  # barter_status is an enum — the form submits the string key (e.g. "no_barter"),
  # which Rails maps to the integer automatically.
  # computer_id is permitted even though it is optional; a blank value means
  # "not installed on any hardware".
  def software_item_params
    params.require(:software_item).permit(
      :software_name_id,
      :software_condition_id,
      :computer_id,
      :version,
      :description,
      :history,
      :barter_status
    )
  end
end
