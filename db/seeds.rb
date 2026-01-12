# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# User.find_or_create_by!(email: "test@example.com") do |user|
#   user.name = "Test User"
#   user.password = "password123"
#   user.role = "admin"
# end
# AdminUser.create!(email: 'admin@example.com', password: 'password', password_confirmation: 'password') if Rails.env.development?
# db/seeds.rb

puts "Creating OAuth Application..."

app = Doorkeeper::Application.find_or_create_by(name: 'Internal SPA') do |a|
  a.redirect_uri = 'urn:ietf:wg:oauth:2.0:oob'
  a.scopes = 'read write'
  a.confidential = false
end

puts "OAuth Application created!"
puts "Name: #{app.name}"
puts "Client ID: #{app.uid}"
puts "---"