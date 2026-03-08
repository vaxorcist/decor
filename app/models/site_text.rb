# decor/app/models/site_text.rb
# version 1.1
# v1.1 (Session 20): Added KNOWN_TEXTS constant — the single source of truth for
#   all named text pages. Drives the upload/delete form selectors, title_for_key,
#   and the admin Texts dropdown. Adding a new page requires only one new entry here.
#   Added title_for_key class method so controllers and views share one lookup.
# v1.0 (Session 18): Initial — key/content model with .for(key) convenience finder.

class SiteText < ApplicationRecord
  # Single source of truth for all known text pages.
  # key:   matches the route default and the DB record key
  # title: human-readable label used in forms, flash messages, and the admin nav
  KNOWN_TEXTS = [
    { key: "readme",       title: "Read Me"      },
    { key: "news",         title: "News"         },
    { key: "barter_trade", title: "Barter Trade" },
    { key: "privacy",      title: "Privacy"      }
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
