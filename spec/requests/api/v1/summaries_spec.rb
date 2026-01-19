# spec/requests/api/v1/summaries_spec.rb
require 'rails_helper'

RSpec.describe "Api::V1::Summaries", type: :request do
  let(:user) { create(:user, :premium) }
  let(:token) { create(:doorkeeper_access_token, resource_owner_id: user.id) }
  let(:headers) { { "Authorization" => "Bearer #{token.token}", "Accept" => "application/json" } }

  describe "Security: ensure_premium_user" do
    it "returns 403 Forbidden if the user is not premium" do
      # Fix: Use 'role: "standard"' instead of 'premium: false'
      non_premium_user = create(:user, role: "standard")
      non_premium_token = create(:doorkeeper_access_token, resource_owner_id: non_premium_user.id)
      
      get api_v1_summaries_path, headers: { "Authorization" => "Bearer #{non_premium_token.token}" }
      
      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)['error']).to eq("Forbidden")
    end
  end

  # When testing the successful path for the premium user:
  let(:user) { create(:user, :premium) } # This uses your trait which sets role to "premium"

  describe "GET /api/v1/summaries" do
    before do
      # Setup data for stats
      recipe = create(:recipe, user: user, title: "Pasta")
      meal_plan = create(:meal_plan, user: user, start_date: Date.today)
      create(:meal_plan_item, meal_plan: meal_plan, plannable: recipe, meal_slot: "dinner")
      create(:shopping_list_item, user: user, is_purchased: true)
      create(:comment, commentable: recipe, user: user)
    end

    it "returns the full dashboard summary" do
      get api_v1_summaries_path, headers: headers
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      # Test user_stats
      expect(json['user_stats']['recipes_count']).to eq(1)
      expect(json['user_stats']['comments_count']).to eq(1)

      # Test recipe summary data
      expect(json['recipes']['total_recipes']).to eq(1)
      
      # Test meal plan summary data
      expect(json['meal_plans']['active_meal_plans']).to eq(1)

      # Test shopping summary data
      expect(json['shopping']['completion_rate']).to eq(100.0)
    end
  end

  describe "Individual Summary Endpoints" do
    it "GET /api/v1/summaries/recipes returns only recipe data" do
      create(:recipe, user: user)
      get recipes_api_v1_summaries_path, headers: headers
      
      json = JSON.parse(response.body)
      expect(json).to have_key('total_recipes')
      expect(json).not_to have_key('meal_plans')
    end

    it "GET /api/v1/summaries/meal_plans returns only meal plan data" do
      create(:meal_plan, user: user, start_date: Date.today)
      get meal_plans_api_v1_summaries_path, headers: headers
      
      json = JSON.parse(response.body)
      expect(json).to have_key('active_meal_plans')
      expect(json).to have_key('upcoming_meals')
    end

    it "GET /api/v1/summaries/shopping returns only shopping data" do
      create(:shopping_list_item, user: user, is_purchased: false)
      get shopping_api_v1_summaries_path, headers: headers
      
      json = JSON.parse(response.body)
      expect(json['pending_items']).to eq(1)
      expect(json).to have_key('items_by_type')
    end
  end

  describe "Complex Data Logic" do
    it "calculates completion_rate correctly for shopping items" do
      create(:shopping_list_item, user: user, is_purchased: true)
      create(:shopping_list_item, user: user, is_purchased: false)
      
      get shopping_api_v1_summaries_path, headers: headers
      json = JSON.parse(response.body)
      
      # 1 purchased / 2 total = 50.0%
      expect(json['completion_rate']).to eq(50.0)
    end

    it "groups meals by slot correctly" do
      meal_plan = create(:meal_plan, user: user)
      create(:meal_plan_item, meal_plan: meal_plan, meal_slot: "breakfast")
      create(:meal_plan_item, meal_plan: meal_plan, meal_slot: "breakfast")
      
      get meal_plans_api_v1_summaries_path, headers: headers
      json = JSON.parse(response.body)
      
      expect(json['meals_by_slot']['breakfast']).to eq(2)
    end
  end
end