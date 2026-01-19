FactoryBot.define do
  # First, define an application
  factory :oauth_application, class: 'Doorkeeper::Application' do
    name         { "Test Application" }
    redirect_uri { "https://localhost:3000" }
  end

  # Second, link the token to that application
  factory :doorkeeper_access_token, class: 'Doorkeeper::AccessToken' do
    application { create(:oauth_application) } # This fixes the NotNullViolation
    resource_owner_id { create(:user).id }
    scopes { 'read write' }
    expires_in { 2.hours }
  end
end
# spec/factories/doorkeeper.rb
# FactoryBot.define do
#   factory :oauth_application, class: 'Doorkeeper::Application' do
#     name { "Internal SPA" }
#     redirect_uri { "urn:ietf:wg:oauth:2.0:oob" }
#     scopes { "read write" }
#     confidential { false }
#   end

#   factory :access_token, class: 'Doorkeeper::AccessToken' do
#     association :application, factory: :oauth_application
#     resource_owner_id { create(:user).id }
#     expires_in { 2.hours }
#     scopes { "read write" }
#   end
# end