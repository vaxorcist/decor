# decor/app/controllers/site_texts_controller.rb
# version 1.1
# v1.1 (Session 73): Bug fix — this controller had its own private
#   title_for_key with only "readme" hardcoded, falling back to key.titleize
#   for everything else. It happened to produce the right title for the 3
#   other pre-existing keys purely by coincidence (.titleize of "news",
#   "barter_trade", "privacy" all happen to match SiteText::KNOWN_TEXTS'
#   configured titles). It was NEVER updated when Session 20 established
#   SiteText.title_for_key / KNOWN_TEXTS as the actual single source of
#   truth — that refactor only touched the admin controller. Caught while
#   adding the 5 Category Help Pages: key "help_computers".titleize gives
#   "Help Computers", not the intended "Computers Help" — this would have
#   shipped a wrong page heading. Fixed by deleting the private method
#   entirely and delegating to SiteText.title_for_key, same as the admin
#   controller already does. No future key will need a change here again.
# v1.0 (Session 18): Public controller for named text pages (README etc.).
#   show: finds the SiteText record by key (injected via route defaults) and
#   renders it as formatted HTML via the render_markdown helper.
#   Displays "== Empty ==" when no record has been uploaded yet.
#   No require_login — these pages are publicly visible.

class SiteTextsController < ApplicationController
  def show
    # key is injected by the route's defaults: { key: "readme" }.
    # Additional named pages can be added as new routes with their own key —
    # see SiteText::KNOWN_TEXTS for the full current list.
    @key       = params[:key]
    @site_text = SiteText.for(@key)

    # Title comes from the single source of truth (SiteText::KNOWN_TEXTS)
    # instead of a separate hardcoded mapping in this controller.
    @title = SiteText.title_for_key(@key)
  end
end
