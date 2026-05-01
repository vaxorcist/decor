# decor/app/models/newsletter.rb
# version 1.0
# Session 56: Newsletter feature — initial implementation.
#
# Stores a newsletter as uploaded markdown plus the rendered HTML equivalent.
# The html_body column is generated automatically from markdown_body before
# every save using the same Redcarpet configuration as ApplicationHelper#render_markdown,
# so the rendering behaviour is identical to the site text pages.
#
# {{user_name}} placeholder:
#   The placeholder is preserved as-is in both markdown_body and html_body.
#   Substitution with the actual recipient's user_name happens at send time
#   inside NewsletterMailer#send_newsletter — not here.
#   This means html_body in the DB always contains the literal "{{user_name}}"
#   string, which is safe to preview in the admin show view.
#
# TEXT columns: approved by user (Session 56). Newsletter body is free-form
# long content; TEXT is the appropriate column type for both body fields.

class Newsletter < ApplicationRecord
  # subject: email subject line shown to recipients.
  validates :subject,       presence: true, length: { maximum: 200 }

  # markdown_body: raw markdown as uploaded by the admin.
  validates :markdown_body, presence: true

  # html_body is generated from markdown_body — never set by external callers.
  # Validated to be present so that a failed render is caught early.
  validates :html_body,     presence: true

  # Generate html_body from markdown_body before validation, not before_save.
  # Rails runs callbacks in order: before_validation → validate → before_save.
  # Using before_validation ensures html_body is populated BEFORE the
  # `validates :html_body, presence: true` check fires — otherwise the
  # validation sees a blank html_body and rejects the record even though
  # generate_html_body would have filled it correctly on before_save.
  # Called on both create and update so that editing markdown_body
  # (if implemented in a future session) keeps html_body in sync.
  before_validation :generate_html_body

  private

  # Converts markdown_body to HTML using the same Redcarpet configuration as
  # ApplicationHelper#render_markdown. Helpers are not available in models, so
  # the Redcarpet setup is replicated here verbatim to keep behaviour identical.
  #
  # Renderer options (mirroring ApplicationHelper v1.2):
  #   with_toc_data:   true  — headings get id= attributes for anchor links
  #   hard_wrap:       true  — single newline → <br>
  #   no_images:       false — allow <img> tags from markdown
  #   no_links:        false — allow <a> tags
  #   safe_links_only: true  — rejects javascript: and other non-http(s) schemes
  #
  # Markdown extensions (mirroring ApplicationHelper v1.2):
  #   tables, fenced_code_blocks, autolink, strikethrough, superscript,
  #   no_intra_emphasis
  def generate_html_body
    return if markdown_body.blank?

    renderer = Redcarpet::Render::HTML.new(
      with_toc_data:   true,
      hard_wrap:       true,
      no_images:       false,
      no_links:        false,
      safe_links_only: true
    )

    markdown = Redcarpet::Markdown.new(
      renderer,
      tables:             true,
      fenced_code_blocks: true,
      autolink:           true,
      strikethrough:      true,
      superscript:        true,
      no_intra_emphasis:  true
    )

    self.html_body = markdown.render(markdown_body)
  end
end
