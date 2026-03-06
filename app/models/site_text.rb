# decor/app/models/site_text.rb
# version 1.0
# Represents a named text page stored in the database as markdown.
# Keys are short internal identifiers ("readme", "about", etc.).
# One record per key — admins upload a .md file to set or replace the content.

class SiteText < ApplicationRecord
  # Key must be present and unique — enforced at both model and DB level.
  validates :key,     presence: true,
                      uniqueness: { case_sensitive: false },
                      length: { maximum: 40 }
  validates :content, presence: true

  # Convenience finder — returns the SiteText for the given key or nil.
  def self.for(key)
    find_by(key: key.to_s.downcase)
  end
end
