# decor/app/controllers/computer_statistics_controller.rb
# version 1.1
# v1.1 (Session 61): Exclude models with zero registered computers.
#   Added .reject { |s| s[:count] == 0 } before sort so models that have
#   never been registered do not appear in the statistics table.
# v1.0 (Session 61): New controller — Computers Statistics page.
#   Single index action.  Public (no require_login) — consistent with the
#   computers index which is also accessible without login.
#
#   Query strategy (two-query approach):
#     Query 1 — Computer.where(device_type: "computer").group(:computer_model_id).count
#       Returns a Hash { computer_model_id => count } for all actual computers.
#       Scoped to device_type: "computer" (integer 0) so peripherals that happen
#       to reference a computer model are NOT included in the count.
#
#     Query 2 — ComputerModel.where(device_type: "computer")
#       Fetches all computer models regardless of whether they have any computers
#       registered, so models with count 0 appear in the table (relevant for
#       "least_common" sort which puts them at the top).
#
#   A single LEFT JOIN + GROUP BY + COUNT query was considered but rejected
#   because peripheral Computer records can reference computer ComputerModel
#   records (confirmed in test fixtures: dec_unibus_router references pdp11_70).
#   An additional join condition (AND computers.device_type = 0) would be needed,
#   which adds complexity without benefit — two simple queries are clearer.
#
#   Sorting is done in Ruby on the mapped array (dataset is small: O(models)).
#     most_common  (default) — count DESC, name ASC for ties
#     least_common            — count ASC,  name ASC for ties
#     model_asc               — name ASC
#     model_desc              — name DESC

class ComputerStatisticsController < ApplicationController
  def index
    # Used by the filter partial for the form action and the Reset link.
    @index_path = computer_statistics_path

    # --- Query 1: per-model computer counts -----------------------------------
    # Only actual computers (device_type: "computer" = 0); peripherals excluded.
    counts = Computer.where(device_type: "computer")
                     .group(:computer_model_id)
                     .count
    # counts is a Hash: { computer_model_id => Integer }

    # --- Query 2: all computer models ----------------------------------------
    # Scoped to device_type: "computer" so peripheral models (e.g. HSC50,
    # DEC VT278) do not appear on this page.
    # Models with count 0 are fetched here but filtered out after the map step.
    models = ComputerModel.where(device_type: "computer")

    # Optional search: filter models by name (case-insensitive LIKE).
    if params[:query].present?
      models = models.where("name LIKE :q", q: "%#{params[:query]}%")
    end

    # --- Build the stats array ------------------------------------------------
    # Each element is a plain Hash with :model (ComputerModel) and :count (Integer).
    # Using a Hash rather than an OpenStruct or separate model object avoids
    # bringing in extra dependencies and is explicit about what is stored.
    # Models with count 0 are excluded — they add no information to a statistics
    # table that only shows registered computers.
    stats = models.map { |m| { model: m, count: counts[m.id] || 0 } }
                  .reject { |s| s[:count] == 0 }

    # --- Sort -----------------------------------------------------------------
    @stats = case params[:sort]
    when "least_common"
      # Count ASC; sub-sort name A-Z for equal counts.
      stats.sort_by { |s| [s[:count], s[:model].name] }
    when "model_asc"
      stats.sort_by { |s| s[:model].name }
    when "model_desc"
      stats.sort_by { |s| s[:model].name }.reverse
    else
      # Default: most_common — count DESC; sub-sort name A-Z for equal counts.
      # Negating :count gives descending order while keeping :name ascending.
      stats.sort_by { |s| [-s[:count], s[:model].name] }
    end
  end
end
