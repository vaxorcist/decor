# decor/app/helpers/application_helper.rb
# version 1.1
# v1.1 (Session 18): Added render_markdown helper — converts a markdown string to
#   safe HTML using the redcarpet gem. Used by the site text show page (README etc.).
#   Standard markdown links work: [text](/path) for internal, [text](https://...) for
#   external. The renderer allows HTML passthrough since only admins supply content.

module ApplicationHelper
  def visible_field(owner, field)
    visibility = owner.send("#{field}_visibility")

    visible = case visibility
    when "public" then true
    when "members_only" then logged_in?
    when "private" then Current.owner == owner
    else false
    end

    return nil unless visible

    if block_given?
      yield
    else
      owner.send(field)
    end
  end

  def empty_state(message)
    tag.div message, class: "col-span-full flex items-center justify-center min-h-32 p-4 bg-stone-100 text-stone-500 text-sm"
  end

  # Renders a markdown string as HTML, marked safe for output in views.
  # Uses redcarpet with a standard set of extensions:
  #   - tables, fenced_code_blocks, autolink, strikethrough, superscript
  #   - hard_wrap: converts single newlines to <br> (friendlier for plain text authors)
  # Only admins can supply content — HTML passthrough is intentionally allowed.
  # Returns an empty string when text is blank.
  def render_markdown(text)
    return "".html_safe if text.blank?

    renderer = Redcarpet::Render::HTML.new(
      hard_wrap:       true,   # single newline → <br>
      no_images:       false,  # allow image tags from markdown
      no_links:        false,  # allow link tags
      safe_links_only: true    # reject non-http(s) link schemes (javascript: etc.)
    )

    markdown = Redcarpet::Markdown.new(
      renderer,
      tables:             true,
      fenced_code_blocks: true,
      autolink:           true,
      strikethrough:      true,
      superscript:        true,
      no_intra_emphasis:  true  # prevents foo_bar_baz from italicising "bar"
    )

    markdown.render(text).html_safe
  end
end
