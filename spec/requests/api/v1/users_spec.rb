# spec/requests/api/v1/users_spec.rb
require 'rails_helper'

RSpec.describe "Api::V1::Users", type: :request do
  let(:user) { create(:user) }
  let(:token) { create(:doorkeeper_access_token, resource_owner_id: user.id) }
  let(:headers) { { "Authorization" => "Bearer #{token.token}", "Accept" => "application/json" } }

  describe "GET /api/v1/profile" do
    context "when authenticated" do
      it "returns the current user's profile" do
        get api_v1_profile_path, headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['id']).to eq(user.id)
        expect(json['email']).to eq(user.email)
      end
    end

    context "when unauthenticated" do
      it "returns 401 unauthorized" do
        get api_v1_profile_path
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "PATCH /api/v1/profile" do
    let(:valid_params) { { user: { name: "Jane Doe", bio: "Updated Bio" } } }

    context "with valid parameters" do
      it "updates the profile and returns 200 ok" do
        patch api_v1_profile_path, params: valid_params, headers: headers
        
        user.reload
        expect(user.name).to eq("Jane Doe")
        expect(user.bio).to eq("Updated Bio")
        expect(response).to have_http_status(:ok)
      end
    end

    context "with invalid parameters" do
      it "returns 422 unprocessable content (handled by BaseController)" do
        # Assuming your User model validates name presence
        allow_any_instance_of(User).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(User.new))
        
        patch api_v1_profile_path, params: { user: { name: "" } }, headers: headers
        
        # BaseController rescues from RecordInvalid with :unprocessable_entity (422)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /api/v1/profile" do
    it "destroys the current user and returns 204 no content" do
      # We reference the user ID before deletion to ensure it's loaded
      user_id = user.id
      
      delete api_v1_profile_path, headers: headers
      
      expect(response).to have_http_status(:no_content)
      expect(User.exists?(user_id)).to be false
    end
  end
end