require 'rails_helper'

RSpec.describe "Tokens", type: :request do
  let(:user) { create(:user, password: 'password123') }

  ## Test POST /api/tokens (Browser Session)
  describe "POST /api/tokens" do
    context "when user is logged in via Devise" do
      before { sign_in user }

      it "returns a successful OAuth token response" do
        post "/api/tokens"
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json).to have_key("access_token")
        expect(json["token_type"]).to eq("Bearer")
      end
    end

    context "when user is not logged in" do
      it "returns unauthorized error" do
        post "/api/tokens"
        
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)["error"]).to eq('Unauthorized - Please log in first')
      end
    end
  end

  ## Test POST /api/tokens/login (Credentials)
  describe "POST /api/tokens/login" do
    context "with valid credentials" do
      it "finds the user and returns a token" do
        post "/api/tokens/login", params: { email: user.email, password: 'password123' }
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["access_token"]).to be_present
      end
    end

    context "with invalid credentials" do
      it "returns error for wrong password" do
        post "/api/tokens/login", params: { email: user.email, password: 'wrong_password' }
        
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)["error"]).to eq('Invalid email or password')
      end

      it "returns error for non-existent email" do
        post "/api/tokens/login", params: { email: "fake@user.com", password: 'password' }
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  ## Test DELETE /api/tokens (Revocation)
  describe "DELETE /api/tokens" do
    context "with a valid token header" do
      let(:token) { create(:doorkeeper_access_token, resource_owner_id: user.id) }


      it "revokes the token and returns success" do
        delete "/api/tokens", headers: { "Authorization" => "Bearer #{token.token}" }
        
        expect(response).to have_http_status(:ok)
        expect(token.reload.revoked_at).not_to be_nil
        expect(JSON.parse(response.body)["message"]).to eq('Token revoked successfully')
      end
    end

    context "without a valid token" do
      it "returns not found when header is missing" do
        delete "/api/tokens"
        expect(response).to have_http_status(:not_found)
      end

      it "returns not found when token is invalid" do
        delete "/api/tokens", headers: { "Authorization" => "Bearer invalid_token" }
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end