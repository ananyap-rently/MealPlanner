# spec/requests/admin/users_spec.rb
require 'rails_helper'

RSpec.describe 'Admin Users', type: :request do
  let(:admin) { create(:admin_user) }
  let!(:user) { create(:user) }
  
  before do
    sign_in admin, scope: :admin_user
  end
  
  describe 'PATCH /admin/users/:id' do
    it 'updates user without password (blank branch)' do
      patch admin_user_path(user), params: {
        user: {
          name: 'Updated Name',
          password: '',
          password_confirmation: ''
        }
      }
      
      expect(response).to redirect_to(admin_user_path(user))
      follow_redirect!
      
      expect(response.body).to include('User was successfully updated')
      expect(user.reload.name).to eq('Updated Name')
    end
    
    it 'updates user with password (non-blank branch)' do
      patch admin_user_path(user), params: {
        user: {
          password: 'newpassword123',
          password_confirmation: 'newpassword123'
        }
      }
      
      expect(response).to redirect_to(admin_user_path(user))
      follow_redirect!
      
      expect(response.body).to include('User was successfully updated')
      
      # Verify password was actually updated
      user.reload
      expect(user.valid_password?('newpassword123')).to be true
    end
  end
end