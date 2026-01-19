# spec/requests/meal_plans_spec.rb
require 'rails_helper'

RSpec.describe "MealPlans", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let!(:meal_plan) { create(:meal_plan, user: user, category: "Test Category") }

  describe "GET /index" do
    context "when authenticated" do
      before { sign_in user }

     it "returns a successful response" do
    get meal_plans_path
    expect(response).to have_http_status(:success)
    end

    end

    context "when unauthenticated" do
      it "redirects to sign in page" do
        get meal_plans_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /create" do
    before { sign_in user }

    context "with valid parameters" do
      let(:valid_params) { { meal_plan: { category: "Keto", start_date: Date.tomorrow } } }

      it "creates a new MealPlan" do
        expect {
          post meal_plans_path, params: valid_params
        }.to change(MealPlan, :count).by(1)
      end

      it "redirects to the created meal plan" do
        post meal_plans_path, params: valid_params
        expect(response).to redirect_to(MealPlan.last)
        expect(flash[:notice]).to eq("Meal plan created successfully.")
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) { { meal_plan: { category: "", start_date: nil } } }

     it "does not create a meal plan and re-renders index" do
        expect {
            post meal_plans_path, params: invalid_params
        }.not_to change(MealPlan, :count)
        
        expect(response).to have_http_status(:success)
        end
    end
  end

  describe "GET /show" do
    before { sign_in user }
    let!(:recipe) { create(:recipe, title: "Spaghetti") }
    
    it "returns a successful response and shows recipes" do
      # Create a meal plan item to test the groupings logic
      create(:meal_plan_item, meal_plan: meal_plan, plannable: recipe, scheduled_date: Date.today)
      
      get meal_plan_path(meal_plan)
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Spaghetti")
      expect(response.body).to include(Date.today.to_s)
    end
  end

  describe "DELETE /destroy" do
    context "when user owns the meal plan" do
      before { sign_in user }

      it "destroys the meal plan" do
        expect {
          delete meal_plan_path(meal_plan)
        }.to change(MealPlan, :count).by(-1)
      end

      it "redirects to index" do
        delete meal_plan_path(meal_plan)
        expect(response).to redirect_to(meal_plans_path)
        expect(flash[:notice]).to eq("Meal plan deleted successfully.")
      end
    end

    context "when user does not own the meal plan" do
      before { sign_in other_user }

      it "does not destroy the meal plan" do
        expect {
          delete meal_plan_path(meal_plan)
        }.not_to change(MealPlan, :count)
      end

      it "redirects to index with an alert" do
        delete meal_plan_path(meal_plan)
        expect(response).to redirect_to(meal_plans_path)
        expect(flash[:alert]).to eq("You can only delete your own meal plans.")
      end
    end
  end
end