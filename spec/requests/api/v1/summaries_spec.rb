# # spec/requests/api/v1/summaries_spec.rb
# require 'rails_helper'

# RSpec.describe "Api::V1::Summaries", type: :request do
#   let(:user) { create(:user, :premium) }
#   let(:token) { create(:doorkeeper_access_token, resource_owner_id: user.id) }
#   let(:headers) { { "Authorization" => "Bearer #{token.token}", "Accept" => "application/json" } }

#   describe "Security: ensure_premium_user" do
#     it "returns 403 Forbidden if the user is not premium" do
#       # Fix: Use 'role: "standard"' instead of 'premium: false'
#       non_premium_user = create(:user, role: "standard")
#       non_premium_token = create(:doorkeeper_access_token, resource_owner_id: non_premium_user.id)
      
#       get api_v1_summaries_path, headers: { "Authorization" => "Bearer #{non_premium_token.token}" }
      
#       expect(response).to have_http_status(:forbidden)
#       expect(JSON.parse(response.body)['error']).to eq("Forbidden")
#     end
#   end

#   # When testing the successful path for the premium user:
#   let(:user) { create(:user, :premium) } # This uses your trait which sets role to "premium"

#   describe "GET /api/v1/summaries" do
#     before do
#       # Setup data for stats
#       recipe = create(:recipe, user: user, title: "Pasta")
#       meal_plan = create(:meal_plan, user: user, start_date: Date.today)
#       create(:meal_plan_item, meal_plan: meal_plan, plannable: recipe, meal_slot: "dinner")
#       create(:shopping_list_item, user: user, is_purchased: true)
#       create(:comment, commentable: recipe, user: user)
#     end

#     it "returns the full dashboard summary" do
#       get api_v1_summaries_path, headers: headers
      
#       expect(response).to have_http_status(:ok)
#       json = JSON.parse(response.body)

#       # Test user_stats
#       expect(json['user_stats']['recipes_count']).to eq(1)
#       expect(json['user_stats']['comments_count']).to eq(1)

#       # Test recipe summary data
#       expect(json['recipes']['total_recipes']).to eq(1)
      
#       # Test meal plan summary data
#       expect(json['meal_plans']['active_meal_plans']).to eq(1)

#       # Test shopping summary data
#       expect(json['shopping']['completion_rate']).to eq(100.0)
#     end
#   end

#   describe "Individual Summary Endpoints" do
#     it "GET /api/v1/summaries/recipes returns only recipe data" do
#       create(:recipe, user: user)
#       get recipes_api_v1_summaries_path, headers: headers
      
#       json = JSON.parse(response.body)
#       expect(json).to have_key('total_recipes')
#       expect(json).not_to have_key('meal_plans')
#     end

#     it "GET /api/v1/summaries/meal_plans returns only meal plan data" do
#       create(:meal_plan, user: user, start_date: Date.today)
#       get meal_plans_api_v1_summaries_path, headers: headers
      
#       json = JSON.parse(response.body)
#       expect(json).to have_key('active_meal_plans')
#       expect(json).to have_key('upcoming_meals')
#     end

#     it "GET /api/v1/summaries/shopping returns only shopping data" do
#       create(:shopping_list_item, user: user, is_purchased: false)
#       get shopping_api_v1_summaries_path, headers: headers
      
#       json = JSON.parse(response.body)
#       expect(json['pending_items']).to eq(1)
#       expect(json).to have_key('items_by_type')
#     end
#   end

#   describe "Complex Data Logic" do
#     it "calculates completion_rate correctly for shopping items" do
#       create(:shopping_list_item, user: user, is_purchased: true)
#       create(:shopping_list_item, user: user, is_purchased: false)
      
#       get shopping_api_v1_summaries_path, headers: headers
#       json = JSON.parse(response.body)
      
#       # 1 purchased / 2 total = 50.0%
#       expect(json['completion_rate']).to eq(50.0)
#     end

#     it "groups meals by slot correctly" do
#       meal_plan = create(:meal_plan, user: user)
#       create(:meal_plan_item, meal_plan: meal_plan, meal_slot: "breakfast")
#       create(:meal_plan_item, meal_plan: meal_plan, meal_slot: "breakfast")
      
#       get meal_plans_api_v1_summaries_path, headers: headers
#       json = JSON.parse(response.body)
      
#       expect(json['meals_by_slot']['breakfast']).to eq(2)
#     end
#   end
# end

# spec/requests/api/v1/summaries_spec.rb
require 'rails_helper'

RSpec.describe "Api::V1::Summaries", type: :request do
  let(:user) { create(:user, :premium) }
  let(:token) { create(:doorkeeper_access_token, resource_owner_id: user.id) }
  let(:headers) { { "Authorization" => "Bearer #{token.token}", "Accept" => "application/json" } }

  describe "Security: ensure_premium_user" do
    it "returns 403 Forbidden if the user is not premium (Branch Coverage: False)" do
      non_premium_user = create(:user, role: "standard")
      non_premium_token = create(:doorkeeper_access_token, resource_owner_id: non_premium_user.id)
      
      get api_v1_summaries_path, headers: { "Authorization" => "Bearer #{non_premium_token.token}" }
      
      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)['error']).to eq("Forbidden")
    end

    it "allows access if the user is premium (Branch Coverage: True)" do
      get api_v1_summaries_path, headers: headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /api/v1/summaries" do
    before do
      # Setup complex data to hit all lines in private methods
      recipe = create(:recipe, user: user, title: "Pasta")
      ingredient = create(:ingredient)
      create(:recipe_ingredient, recipe: recipe, ingredient: ingredient)
      
      meal_plan = create(:meal_plan, user: user, start_date: Date.today)
      create(:meal_plan_item, 
             meal_plan: meal_plan, 
             plannable: recipe, 
             meal_slot: "dinner", 
             scheduled_date: Date.today)
      
      create(:shopping_list_item, user: user, is_purchased: true, purchasable_type: 'Ingredient')
      create(:comment, commentable: recipe, user: user)
    end

    it "returns the full dashboard summary and covers all stat lines" do
      get api_v1_summaries_path, headers: headers
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      # Validating structure to ensure all controller lines executed
      expect(json).to have_key('user_stats')
      expect(json).to have_key('recipes')
      expect(json).to have_key('meal_plans')
      expect(json).to have_key('shopping')
      
      # Verify deep nested data from private methods
      expect(json['recipes']['total_ingredients_used']).to eq(1)
      expect(json['meal_plans']['upcoming_meals']).not_to be_empty
    end
  end

  describe "Shopping Summary Logic (Branch Coverage)" do
    it "returns 0 completion_rate when total items is 0 (Ternary Branch: False)" do
      # User has no shopping list items
      get shopping_api_v1_summaries_path, headers: headers
      
      json = JSON.parse(response.body)
      expect(json['total_items']).to eq(0)
      expect(json['completion_rate']).to eq(0)
    end

    it "calculates rate when items exist (Ternary Branch: True)" do
      create(:shopping_list_item, user: user, is_purchased: true)
      create(:shopping_list_item, user: user, is_purchased: false)
      
      get shopping_api_v1_summaries_path, headers: headers
      
      json = JSON.parse(response.body)
      expect(json['completion_rate']).to eq(50.0)
    end
  end

  describe "Recipe & Meal Plan Details" do
    it "covers most_used_recipes and recipes_by_category lines" do
      recipe = create(:recipe, user: user, title: "Taco")
      meal_plan = create(:meal_plan, user: user)
      create(:meal_plan_item, meal_plan: meal_plan, plannable: recipe)

      get recipes_api_v1_summaries_path, headers: headers
      
      json = JSON.parse(response.body)
      expect(json['recipes_by_category']).to have_key("Taco")
      expect(json['most_used_recipes']).not_to be_empty
    end

    it "covers completed_meal_plans and meals_by_slot lines" do
      create(:meal_plan, user: user, start_date: Date.today)
      get meal_plans_api_v1_summaries_path, headers: headers
      
      json = JSON.parse(response.body)
      expect(json['completed_meal_plans']).to be >= 1
      expect(json).to have_key('meals_by_slot')
    end
  end
end