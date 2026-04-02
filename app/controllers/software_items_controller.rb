# decor/app/controllers/software_items_controller.rb
# version 1.0
# Session 45: Software feature Session C — read-only actions.
#   show action only; create/edit/update/destroy will be added in Session D.
#
#   Access model: no require_login before_action — show is publicly accessible,
#   consistent with ComputersController and ComponentsController show pages.
#   Ownership is irrelevant for read access; any visitor may view a software
#   item detail page.
#
#   eager_load in set_software_item avoids N+1 queries when the view accesses
#   @software_item.software_name, .software_condition, .computer.computer_model,
#   and .owner.

class SoftwareItemsController < ApplicationController
  before_action :set_software_item

  # GET /software_items/:id
  # Publicly accessible detail page for a single software item.
  def show
  end

  private

  # Eager-loads all associations accessed by the show view in a single query.
  # :software_name and :software_condition are always joined.
  # computer: :computer_model is left-joined (nullable computer_id).
  # :owner is joined for the "back to owner" link in the view.
  def set_software_item
    @software_item = SoftwareItem
                       .eager_load(:software_name, :software_condition,
                                   :owner, computer: :computer_model)
                       .find(params[:id])
  end
end
