# decor/app/controllers/admin/site_texts_controller.rb
# version 1.3
# v1.3 (Session 73): Bug fix — url_for_key was a hardcoded `case` statement
#   mapping key => route helper, requiring a manual edit here every single
#   time a new SiteText::KNOWN_TEXTS entry was added (a "touch N places, miss
#   one" trap — the same shape of mistake as the Session 64 admin-nav-menu
#   gap and the Session 68 documentation gap). Every existing route's `as:`
#   name is IDENTICAL to its key (config/routes.rb, both before and after
#   v3.7), so the case statement is replaced with one dynamic call:
#   `send("#{key}_path")`. Adding a future SiteText page now requires editing
#   ONLY site_text.rb (KNOWN_TEXTS) + routes.rb (as: == key) — this file
#   never needs to change again for that purpose. Falls back to root_path if
#   the helper doesn't exist (same behavior as the old `else root_path`
#   branch), e.g. if a key is ever added to KNOWN_TEXTS without a matching
#   route.
# v1.2 (Session 53): Added Download option.
#   download_confirm: renders selector page — admin picks which text to download.
#   download:         streams the stored content as a <key>.md file attachment.
#                     Returns alert redirect if the text has not been uploaded yet.
# v1.1 (Session 20): Generalised for all text pages via KNOWN_TEXTS constant on SiteText.
#   new:            renders the upload form with a key selector (no key in URL needed).
#   create:         unchanged logic; key now comes from form params selector.
#   delete_confirm: new action — renders confirmation page for the chosen key.
#   destroy:        unchanged logic; key comes from URL param as before.
#   title_for_key:  removed — delegated to SiteText.title_for_key (single source of truth).
#   After successful upload, redirects to the public page for the uploaded key.
# v1.0 (Session 18): Initial — new/create/destroy for readme only.

class Admin::SiteTextsController < Admin::BaseController
  def new
    # No key param needed — the form presents a selector for all known texts.
    # Pre-select the first entry as the default.
    @known_texts  = SiteText.options_for_select_list
    @default_key  = SiteText::KNOWN_TEXTS.first[:key]
  end

  def create
    @key = params[:key].to_s.downcase

    uploaded_file = params[:file]

    unless uploaded_file.present?
      flash[:alert] = "Please select a .md file to upload."
      redirect_to new_admin_site_text_path and return
    end

    # Read the raw file content — .md files are plain text, no binary concerns.
    content = uploaded_file.read.force_encoding("UTF-8")

    # find_or_initialize_by: updates existing record or creates a new one (upsert).
    site_text         = SiteText.find_or_initialize_by(key: @key)
    site_text.content = content

    title = SiteText.title_for_key(@key)

    if site_text.save
      # Redirect to the public page that was just updated so the admin can verify it.
      redirect_to url_for_key(@key), notice: "#{title} was successfully updated."
    else
      flash[:alert] = "Could not save: #{site_text.errors.full_messages.to_sentence}"
      redirect_to new_admin_site_text_path
    end
  end

  def delete_confirm
    # Renders a confirmation page with a key selector and a Delete button.
    # No key required in the URL — the admin picks the text on the page.
    @known_texts = SiteText.options_for_select_list
    @default_key = SiteText::KNOWN_TEXTS.first[:key]
  end

  def destroy
    key       = params[:key].to_s
    site_text = SiteText.for(key)
    title     = SiteText.title_for_key(key)

    if site_text
      site_text.destroy
      redirect_to admin_owners_path, notice: "#{title} was successfully deleted."
    else
      redirect_to admin_owners_path, alert: "#{title} not found."
    end
  end

  def download_confirm
    # Renders a selector page so the admin can choose which text to download.
    # No key required in the URL — the admin picks it on the page.
    @known_texts = SiteText.options_for_select_list
    @default_key = SiteText::KNOWN_TEXTS.first[:key]
  end

  def download
    key       = params[:key].to_s
    site_text = SiteText.for(key)
    title     = SiteText.title_for_key(key)

    if site_text
      # Send the stored Markdown content as a file download.
      # disposition: "attachment" forces the browser to save rather than display.
      send_data site_text.content,
                filename:    "#{key}.md",
                type:        "text/markdown; charset=utf-8",
                disposition: "attachment"
    else
      # Text has never been uploaded — nothing to download.
      redirect_to download_confirm_admin_site_texts_path,
                  alert: "#{title} has not been uploaded yet — nothing to download."
    end
  end

  private

  # Returns the public path for a given key so the admin is redirected to the
  # page they just updated. Relies on the project convention that every
  # site_texts route's `as:` name is identical to its key (config/routes.rb) —
  # e.g. key "help_computers" => help_computers_path. Falls back to root_path
  # if the key has no matching named route (e.g. a KNOWN_TEXTS entry added
  # without a corresponding route).
  def url_for_key(key)
    send("#{key}_path")
  rescue NoMethodError
    root_path
  end
end
