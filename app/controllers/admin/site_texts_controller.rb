# decor/app/controllers/admin/site_texts_controller.rb
# version 1.0
# v1.0 (Session 18): Admin controller for uploading and deleting named text pages.
#   new:     renders the upload form (key passed as query param, e.g. ?key=readme)
#   create:  reads the uploaded .md file, upserts the SiteText record (replace if exists)
#   destroy: deletes the SiteText record identified by params[:key]
#
# Inherits from Admin::BaseController — require_admin is enforced there.

class Admin::SiteTextsController < Admin::BaseController
  def new
    # key is passed as a query param from the admin nav link, e.g. ?key=readme.
    # The form's hidden field carries it through to create.
    @key       = params[:key] || "readme"
    @title     = title_for_key(@key)
    # Show the currently stored content (if any) so the admin knows what exists.
    @site_text = SiteText.for(@key)
  end

  def create
    @key = params[:key] || "readme"

    uploaded_file = params[:file]

    unless uploaded_file.present?
      flash[:alert] = "Please select a .md file to upload."
      redirect_to new_admin_site_text_path(key: @key) and return
    end

    # Read the raw file content. .md files are plain text — no binary concerns.
    content = uploaded_file.read.force_encoding("UTF-8")

    # find_or_initialize_by: updates existing record or creates a new one.
    # This is the "replace if exists" behaviour requested.
    site_text = SiteText.find_or_initialize_by(key: @key)
    site_text.content = content

    if site_text.save
      redirect_to readme_path, notice: "#{title_for_key(@key)} was successfully updated."
    else
      flash[:alert] = "Could not save: #{site_text.errors.full_messages.to_sentence}"
      redirect_to new_admin_site_text_path(key: @key)
    end
  end

  def destroy
    site_text = SiteText.for(params[:key])

    if site_text
      site_text.destroy
      redirect_to admin_owners_path, notice: "#{title_for_key(params[:key])} was successfully deleted."
    else
      redirect_to admin_owners_path, alert: "#{title_for_key(params[:key])} not found."
    end
  end

  private

  # Maps internal key identifiers to human-readable titles.
  # Kept in sync with SiteTextsController#title_for_key.
  def title_for_key(key)
    {
      "readme" => "Read Me"
    }.fetch(key.to_s, key.to_s.titleize)
  end
end
