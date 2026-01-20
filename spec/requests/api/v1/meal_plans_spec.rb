# spec/requests/api/v1/meal_plans_spec.rb
require 'rails_helper'

RSpec.describe "Api::V1::MealPlans", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  # Doorkeeper Tokens
  let(:token) { create(:doorkeeper_access_token, resource_owner_id: user.id) }
  let(:other_token) { create(:doorkeeper_access_token, resource_owner_id: other_user.id) }

  # Headers
  let(:headers) { { "Authorization" => "Bearer #{token.token}", "Accept" => "application/json" } }
  let(:other_headers) { { "Authorization" => "Bearer #{other_token.token}", "Accept" => "application/json" } }

  describe "GET /api/v1/meal_plans" do
    context "when authenticated" do
      let!(:meal_plan) { create(:meal_plan, user: user) }
      
      it "returns a successful response" do
        get api_v1_meal_plans_path, headers: headers
        expect(response).to have_http_status(:ok)
      end

      it "returns meal plans with nested user data" do
        get api_v1_meal_plans_path, headers: headers
        json = JSON.parse(response.body)
        
        expect(json.first['user']['email']).to eq(user.email)
        expect(json.first['category']).to eq(meal_plan.category)
      end
    end

    context "when unauthenticated" do
      it "returns 401" do
        get api_v1_meal_plans_path
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/v1/meal_plans" do
    let(:valid_params) { { meal_plan: { category: "Keto", start_date: Date.today } } }

    it "creates a new meal plan for the current user" do
      expect {
        post api_v1_meal_plans_path, params: valid_params, headers: headers
      }.to change(MealPlan, :count).by(1)
      
      expect(MealPlan.last.user).to eq(user)
      expect(response).to have_http_status(:created)
    end
  end

  describe "GET /api/v1/meal_plans/:id" do
    let!(:meal_plan) { create(:meal_plan, user: user) }
    let!(:item) { create(:meal_plan_item, meal_plan: meal_plan, scheduled_date: Date.today) }
   let!(:comment) { create(:comment, :for_meal_plan, commentable: meal_plan, user: user) }
    it "returns complex nested structure (items grouped by date and comments)" do
  get api_v1_meal_plan_path(meal_plan), headers: headers
  json = JSON.parse(response.body)

  # Validate the meal plan data
  expect(json['meal_plan']['id']).to eq(meal_plan.id)
  
  # Validate comments array
  expect(json['comments']).not_to be_empty
  expect(json['comments'].first['content']).to eq(comment.content)
  expect(json['comments'].first['user']['id']).to eq(user.id)
end
   
  end

  describe "DELETE /api/v1/meal_plans/:id" do
    let!(:meal_plan) { create(:meal_plan, user: user) }

    context "when the owner deletes" do
      it "destroys the meal plan" do
        expect {
          delete api_v1_meal_plan_path(meal_plan), headers: headers
        }.to change(MealPlan, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end
    end

    context "when another user tries to delete" do
      it "does not destroy and returns forbidden" do
        expect {
          delete api_v1_meal_plan_path(meal_plan), headers: other_headers
        }.not_to change(MealPlan, :count)
        
        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json['error']).to eq("You can only delete your own meal plans.")
      end
    end
  end
end