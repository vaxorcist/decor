# decor/script/generate_fixture_passwords.rb
# Run this script to generate BCrypt digests for test fixtures
# Usage: ruby script/generate_fixture_passwords.rb

require "bcrypt"

passwords = {
  "Alice (DecorAdmin2026!)" => "DecorAdmin2026!",
  "Bob (DecorUser2026!)" => "DecorUser2026!"
}

puts "=" * 80
puts "BCrypt Digests for Test Fixtures"
puts "=" * 80
puts ""
puts "Copy these digests into test/fixtures/owners.yml"
puts ""

passwords.each do |label, password|
  digest = BCrypt::Password.create(password, cost: 12)
  puts "#{label}:"
  puts digest
  puts ""
end

puts "=" * 80
