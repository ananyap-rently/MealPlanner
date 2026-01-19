require 'rails_helper'

RSpec.describe "Users", type: :request do
  let(:user) { create(:user) }

  describe "GET /show" do
    context "when authenticated" do
      before { sign_in user }

      it "returns a successful response" do
        get profile_path # This matches your controller redirect
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to sign in page" do
        get profile_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /edit" do
    context "when authenticated" do
      before { sign_in user }

      it "returns a successful response" do
        get edit_profile_path # Changed from edit_user_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to sign in page" do
        get edit_profile_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "PATCH /update" do
    let(:valid_params) { { user: { name: "New Name", bio: "New Bio" } } }
    
    # To make 'invalid' params work, your User model needs a validation (e.g., validates :name, presence: true)
    let(:invalid_params) { { user: { name: "" } } } 

    context "when authenticated" do
      before { sign_in user }

      context "with valid parameters" do
        it "updates the user" do
          patch profile_path, params: valid_params # Changed from user_path(user)
          user.reload
          expect(user.name).to eq("New Name")
        end

        it "redirects to profile path" do
          patch profile_path, params: valid_params
          expect(response).to redirect_to(profile_path)
          expect(flash[:notice]).to eq("Profile updates successfully")
        end
      end

      context "with invalid parameters" do
        it "returns unprocessable entity status" do
          patch profile_path, params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe "DELETE /destroy" do
    context "when authenticated" do
      before { sign_in user }

      it "destroys the user" do
        user # hit the 'let' to ensure it's created
        expect {
          delete profile_path # Changed from user_path(user)
        }.to change(User, :count).by(-1)
      end

     it "resets the session" do
        delete profile_path
        # Check that the session is empty or that the user is no longer authenticated
        expect(session[:"warden.user.user.key"]).to be_nil
      end

      it "redirects to root path" do
        delete profile_path
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq("Account deleted successfully")
      end
    end
  end
end