# decor/app/models/site_text.rb
# version 1.2
# v1.2 (Session 73): Category Help Pages feature. Added 5 new KNOWN_TEXTS
#   entries — one per owner-facing device/software category. No schema
#   change: this table already stores an arbitrary key/content pair per row,
#   so new pages are pure data (this constant + a route + a nav link), same
#   as every prior addition to this list. Each new key's route `as:` name
#   (config/routes.rb v3.7) is IDENTICAL to its key string here — this
#   convention is now load-bearing, not just tidy: admin/site_texts_
#   controller.rb v1.3's url_for_key(key) does `send("#{key}_path")` to find
#   the public page to redirect to after an upload, for any key, without a
#   hardcoded per-key mapping. Keep this convention for any future addition.
# v1.1 (Session 20): Added KNOWN_TEXTS constant — the single source of truth for
#   all named text pages. Drives the upload/delete form selectors, title_for_key,
#   and the admin Texts dropdown. Adding a new page requires only one new entry here.
#   Added title_for_key class method so controllers and views share one lookup.
# v1.0 (Session 18): Initial — key/content model with .for(key) convenience finder.

class SiteText < ApplicationRecord
  # Single source of truth for all known text pages.
  # key:   matches the route default AND the route's `as:` name (REQUIRED,
  #        see v1.2 changelog note above) AND the DB record key
  # title: human-readable label used in forms, flash messages, and the admin nav
  KNOWN_TEXTS = [
    { key: "readme",           title: "Read Me"          },
    { key: "news",             title: "News"             },
    { key: "barter_trade",     title: "Barter Trade"     },
    { key: "privacy",          title: "Privacy"          },
    # Category Help Pages — added Session 73.
    { key: "help_computers",   title: "Computers Help"   },
    { key: "help_peripherals", title: "Peripherals Help" },
    { key: "help_components",  title: "Components Help"  },
    { key: "help_connections", title: "Connections Help" },
    { key: "help_software",    title: "Software Help"    }
  ].freeze

  # Key must be present and unique — enforced at both model and DB level.
  validates :key,     presence: true,
                      uniqueness: { case_sensitive: false },
                      length: { maximum: 40 }
  validates :content, presence: true

  # Convenience finder — returns the SiteText for the given key or nil.
  def self.for(key)
    find_by(key: key.to_s.downcase)
  end

  # Returns the human-readable title for a given key.
  # Falls back to a titleized version of the key for any unregistered keys.
  def self.title_for_key(key)
    entry = KNOWN_TEXTS.find { |t| t[:key] == key.to_s }
    entry ? entry[:title] : key.to_s.titleize
  end

  # Returns options array suitable for options_for_select in a form selector.
  # Format: [["Read Me", "readme"], ["News", "news"], ...]
  def self.options_for_select_list
    KNOWN_TEXTS.map { |t| [t[:title], t[:key]] }
  end
end
