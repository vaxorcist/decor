# decor/test/models/site_text_test.rb
# version 1.0
# v1.0 (Session 20): New file. Unit tests for SiteText model class methods
#   introduced in v1.1: KNOWN_TEXTS constant structure, title_for_key, and
#   options_for_select_list. Also covers the existing .for convenience finder.
#   No fixtures needed — records created inline where required.

require "test_helper"

class SiteTextTest < ActiveSupport::TestCase
  # ── KNOWN_TEXTS constant ────────────────────────────────────────────────────

  test "KNOWN_TEXTS contains all expected keys" do
    keys = SiteText::KNOWN_TEXTS.map { |t| t[:key] }
    assert_includes keys, "readme"
    assert_includes keys, "news"
    assert_includes keys, "barter_trade"
    assert_includes keys, "privacy"
  end

  test "every KNOWN_TEXTS entry has a key and a title" do
    SiteText::KNOWN_TEXTS.each do |entry|
      assert entry[:key].present?,   "Expected :key to be present in #{entry.inspect}"
      assert entry[:title].present?, "Expected :title to be present in #{entry.inspect}"
    end
  end

  # ── title_for_key ───────────────────────────────────────────────────────────

  test "title_for_key returns correct title for known keys" do
    assert_equal "Read Me",      SiteText.title_for_key("readme")
    assert_equal "News",         SiteText.title_for_key("news")
    assert_equal "Barter Trade", SiteText.title_for_key("barter_trade")
    assert_equal "Privacy",      SiteText.title_for_key("privacy")
  end

  test "title_for_key falls back to titleize for unknown keys" do
    assert_equal "About Us", SiteText.title_for_key("about_us")
  end

  test "title_for_key accepts symbol-like string input" do
    assert_equal "Read Me", SiteText.title_for_key("readme")
  end

  # ── options_for_select_list ─────────────────────────────────────────────────

  test "options_for_select_list returns array of [title, key] pairs" do
    options = SiteText.options_for_select_list
    assert_instance_of Array, options
    options.each do |pair|
      assert_equal 2, pair.length, "Expected [title, key] pair, got #{pair.inspect}"
      assert pair[0].present?, "Title should not be blank"
      assert pair[1].present?, "Key should not be blank"
    end
  end

  test "options_for_select_list title comes first, key second" do
    # First entry should be ["Read Me", "readme"]
    first = SiteText.options_for_select_list.first
    assert_equal "Read Me", first[0]
    assert_equal "readme",  first[1]
  end

  test "options_for_select_list covers all KNOWN_TEXTS entries" do
    option_keys = SiteText.options_for_select_list.map(&:last)
    SiteText::KNOWN_TEXTS.each do |entry|
      assert_includes option_keys, entry[:key]
    end
  end

  # ── .for convenience finder ─────────────────────────────────────────────────

  test ".for returns the matching SiteText record" do
    record = SiteText.create!(key: "readme", content: "# Hello")
    assert_equal record, SiteText.for("readme")
  ensure
    record&.destroy
  end

  test ".for returns nil when no record exists for the key" do
    assert_nil SiteText.for("nonexistent_key_xyz")
  end

  test ".for is case-insensitive" do
    record = SiteText.create!(key: "readme", content: "# Hello")
    assert_equal record, SiteText.for("README")
  ensure
    record&.destroy
  end

  # ── validations ─────────────────────────────────────────────────────────────

  test "is invalid without a key" do
    site_text = SiteText.new(content: "Some content")
    assert_not site_text.valid?
    assert_includes site_text.errors[:key], "can't be blank"
  end

  test "is invalid without content" do
    site_text = SiteText.new(key: "test_key")
    assert_not site_text.valid?
    assert_includes site_text.errors[:content], "can't be blank"
  end

  test "is invalid with a duplicate key" do
    SiteText.create!(key: "unique_key_test", content: "First")
    duplicate = SiteText.new(key: "unique_key_test", content: "Second")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:key], "has already been taken"
  ensure
    SiteText.find_by(key: "unique_key_test")&.destroy
  end
end
