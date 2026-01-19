require 'rails_helper'

RSpec.describe "Admin::AdminUsers", type: :request do
  let!(:admin_user) { create(:admin_user) }

  before do
    # Devise helper to sign in the admin
   #allow(Devise).to receive(:mappings).and_return({ admin_user: Devise.mappings[:admin_user] })
    sign_in admin_user
  
  end

  describe "GET /admin/admin_users" do
    it "renders the index page successfully" do
      get admin_admin_users_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Admin Users")
      expect(response.body).to include(admin_user.email)
    end
  end

  describe "POST /admin/admin_users" do
    context "with valid parameters" do
      let(:valid_params) do
        {
          admin_user: {
            email: "new_admin@example.com",
            password: "password123",
            password_confirmation: "password123"
          }
        }
      end

      it "creates a new AdminUser and redirects" do
        expect {
          post admin_admin_users_path, params: valid_params
        }.to change(AdminUser, :count).by(1)

        expect(response).to have_http_status(:found) # Redirect after create
        follow_redirect!
        expect(response.body).to include("Admin user was successfully created.")
      end
    end

    context "with invalid parameters" do
      it "does not create a user and shows errors" do
        expect {
          post admin_admin_users_path, params: { admin_user: { email: "" } }
        }.not_to change(AdminUser, :count)
        
        expect(response.body).to include("can&#39;t be blank")
      end
    end
  end

  describe "PATCH /admin/admin_users/:id" do
    it "updates the admin user email" do
      patch admin_admin_user_path(admin_user), params: { 
        admin_user: { email: "updated_admin@example.com" } 
      }
      
      expect(admin_user.reload.email).to eq("updated_admin@example.com")
      expect(response).to redirect_to(admin_admin_user_path(admin_user))
    end
  end

  describe "DELETE /admin/admin_users/:id" do
    it "deletes the user" do
      another_admin = create(:admin_user)
      expect {
        delete admin_admin_user_path(another_admin)
      }.to change(AdminUser, :count).by(-1)
      
      expect(response).to redirect_to(admin_admin_users_path)
    end
  end
end
