# decor/app/controllers/admin/site_texts_controller.rb
# version 1.1
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

  private

  # Returns the public path for a given key so the admin is redirected to the
  # page they just updated. Falls back to root if the key has no named route.
  def url_for_key(key)
    case key
    when "readme"       then readme_path
    when "news"         then news_path
    when "barter_trade" then barter_trade_path
    when "privacy"      then privacy_path
    else root_path
    end
  end
end
