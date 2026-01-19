# spec/requests/role_selections_spec.rb
require 'rails_helper'

RSpec.describe "RoleSelections", type: :request do
  # Explicitly set role to nil to avoid unexpected redirects in the 'new' action
  let(:user) { create(:user, role: nil) }

  describe "GET /role_selection/new" do
    context "when authenticated" do
      before { sign_in user }

      context "when user has no role" do
        it "returns a successful response" do
          get new_role_selection_path
          expect(response).to have_http_status(:success)
        end

        it "captures the referer in the session" do
          # Headers must be passed as the second argument or within the headers: key
          get new_role_selection_path, headers: { "HTTP_REFERER" => "/previous-page" }
          expect(session[:return_to]).to eq("/previous-page")
        end
      end

      context "when user already has a role" do
        # Create a user that already has a role to trigger the redirect logic
        let(:user_with_role) { create(:user, role: 'standard') }
        before { sign_in user_with_role }

        it "redirects to root path with a notice" do
          get new_role_selection_path
          expect(response).to redirect_to(root_path)
          expect(flash[:notice]).to eq('You have already selected your role.')
        end
      end
    end

    context "when unauthenticated" do
      it "redirects to sign in page" do
        get new_role_selection_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /role_selection" do
    context "when authenticated" do
      before { sign_in user }

      context "with valid role 'standard'" do
        it "updates the user role and redirects to root" do
          # Changed to singular 'role_selection_path' to match your routes.rb
          post role_selection_path, params: { role: 'standard' }
          
          user.reload
          expect(user.role).to eq('standard')
          expect(response).to redirect_to(root_path)
          expect(flash[:notice]).to include('Welcome to our platform')
        end
      end

      context "with valid role 'premium'" do
        it "updates the user role and redirects to stored session path" do
          # Set the session via a prior request
          get new_role_selection_path, headers: { "HTTP_REFERER" => "/special-feature" }
          
          post role_selection_path, params: { role: 'premium' }
          
          user.reload
          expect(user.role).to eq('premium')
          expect(response).to redirect_to("/special-feature")
          expect(flash[:notice]).to include('full access to all features')
        end
      end

      context "with invalid parameters" do
        it "flashes error for blank role" do
          post role_selection_path, params: { role: '' }
          expect(response).to redirect_to(new_role_selection_path)
          expect(flash[:alert]).to eq('Please select a role.')
        end

        it "flashes error for unauthorized role types" do
          post role_selection_path, params: { role: 'admin' }
          expect(response).to redirect_to(new_role_selection_path)
          expect(flash[:alert]).to eq('Invalid role selected.')
        end
      end

      context "when database update fails" do
        it "redirects to new with a failure message" do
          allow_any_instance_of(User).to receive(:update).and_return(false)
          
          post role_selection_path, params: { role: 'standard' }
          expect(response).to redirect_to(new_role_selection_path)
          expect(flash[:alert]).to eq('Failed to update role. Please try again.')
        end
      end
    end

    context "when unauthenticated" do
      it "does not update the user and redirects to login" do
        post role_selection_path, params: { role: 'standard' }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end