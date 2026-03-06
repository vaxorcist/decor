# decor/app/controllers/site_texts_controller.rb
# version 1.0
# v1.0 (Session 18): Public controller for named text pages (README etc.).
#   show: finds the SiteText record by key (injected via route defaults) and
#   renders it as formatted HTML via the render_markdown helper.
#   Displays "== Empty ==" when no record has been uploaded yet.
#   No require_login — these pages are publicly visible.

class SiteTextsController < ApplicationController
  def show
    # key is injected by the route's defaults: { key: "readme" }.
    # Additional named pages can be added as new routes with their own key.
    @key       = params[:key]
    @site_text = SiteText.for(@key)

    # Title is derived from the key for the page heading.
    # "readme" → "Read Me" via a simple mapping; extend as new keys are added.
    @title = title_for_key(@key)
  end

  private

  # Maps internal key identifiers to human-readable page titles.
  # Extend this hash as new text pages are added.
  def title_for_key(key)
    {
      "readme" => "Read Me"
    }.fetch(key, key.titleize)
  end
end
