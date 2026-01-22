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

    context "when user has no meal plans" do
      it "returns empty array" do
        MealPlan.destroy_all
        get api_v1_meal_plans_path, headers: headers
        json = JSON.parse(response.body)
        
        expect(json).to eq([])
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /api/v1/meal_plans" do
    let(:valid_params) { { meal_plan: { category: "Keto", start_date: Date.today } } }

    context "when authenticated" do
      it "creates a new meal plan for the current user" do
        expect {
          post api_v1_meal_plans_path, params: valid_params, headers: headers
        }.to change(MealPlan, :count).by(1)
        
        expect(MealPlan.last.user).to eq(user)
        expect(response).to have_http_status(:created)
      end

      it "returns unprocessable content when validation fails" do
        allow_any_instance_of(MealPlan).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(MealPlan.new))
        
        post api_v1_meal_plans_path, params: valid_params, headers: headers
        
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns bad request when meal_plan parameter is missing" do
        post api_v1_meal_plans_path, params: {}, headers: headers
        
        expect(response).to have_http_status(:bad_request)
      end
    end

    context "when unauthenticated" do
      it "returns 401 unauthorized" do
        post api_v1_meal_plans_path, params: valid_params
        expect(response).to have_http_status(:unauthorized)
      end

      it "does not create a meal plan" do
        expect {
          post api_v1_meal_plans_path, params: valid_params
        }.not_to change(MealPlan, :count)
      end
    end
  end

  describe "GET /api/v1/meal_plans/:id" do
    let!(:meal_plan) { create(:meal_plan, user: user) }
    let!(:item) { create(:meal_plan_item, meal_plan: meal_plan, scheduled_date: Date.today) }
    let!(:comment) { create(:comment, :for_meal_plan, commentable: meal_plan, user: user) }

    context "when meal plan exists" do
      it "returns complex nested structure (items grouped by date and comments)" do
        get api_v1_meal_plan_path(meal_plan), headers: headers
        json = JSON.parse(response.body)

        # Validate the meal plan data
        expect(json['meal_plan']['id']).to eq(meal_plan.id)
        
        # Validate comments array
        expect(json['comments']).not_to be_empty
        expect(json['comments'].first['content']).to eq(comment.content)
        expect(json['comments'].first['user']['id']).to eq(user.id)

        # Validate items_by_date structure
        expect(json['items_by_date']).not_to be_empty
        expect(json['items_by_date'][Date.today.to_s]).not_to be_empty
      end

      it "returns plannable with title when respond_to title is true" do
        get api_v1_meal_plan_path(meal_plan), headers: headers
        json = JSON.parse(response.body)

        # Verify the item has plannable with title (Recipe responds to :title)
        plannable_data = json['items_by_date'][Date.today.to_s].first['plannable']
        expect(plannable_data).not_to be_nil
        expect(plannable_data['title']).not_to be_nil
      end

      it "returns plannable with item_name when respond_to item_name is true" do
        get api_v1_meal_plan_path(meal_plan), headers: headers
        json = JSON.parse(response.body)

        # Verify the item has plannable
        plannable_data = json['items_by_date'][Date.today.to_s].first['plannable']
        expect(plannable_data).not_to be_nil
        # Item has item_name, Recipe doesn't - so this should be nil for Recipe
        expect(plannable_data).to have_key('item_name')
      end

      it "returns plannable with quantity when respond_to quantity is true" do
        get api_v1_meal_plan_path(meal_plan), headers: headers
        json = JSON.parse(response.body)

        # Verify the item has plannable
        plannable_data = json['items_by_date'][Date.today.to_s].first['plannable']
        expect(plannable_data).not_to be_nil
        # Verify quantity key exists
        expect(plannable_data).to have_key('quantity')
      end

      it "handles plannable without title attribute (respond_to returns false)" do
        plannable = double("Plannable", id: 1)
        allow(plannable).to receive(:respond_to?).with(:title).and_return(false)
        allow(plannable).to receive(:respond_to?).with(:item_name).and_return(true)
        allow(plannable).to receive(:respond_to?).with(:quantity).and_return(true)
        allow(plannable).to receive(:item_name).and_return("Test Item")
        allow(plannable).to receive(:quantity).and_return(5)
        
        item_without_title = create(:meal_plan_item, meal_plan: meal_plan, scheduled_date: Date.today)
        allow_any_instance_of(MealPlanItem).to receive(:plannable).and_return(plannable)
        
        get api_v1_meal_plan_path(meal_plan), headers: headers
        json = JSON.parse(response.body)

        plannable_data = json['items_by_date'][Date.today.to_s].last['plannable']
        expect(plannable_data['title']).to be_nil
        expect(plannable_data['item_name']).to eq("Test Item")
        expect(plannable_data['quantity']).to eq(5)
      end

      it "handles plannable without item_name attribute (respond_to returns false)" do
        plannable = double("Plannable", id: 1)
        allow(plannable).to receive(:respond_to?).with(:title).and_return(true)
        allow(plannable).to receive(:respond_to?).with(:item_name).and_return(false)
        allow(plannable).to receive(:respond_to?).with(:quantity).and_return(true)
        allow(plannable).to receive(:title).and_return("Test Title")
        allow(plannable).to receive(:quantity).and_return(5)
        
        item_without_item_name = create(:meal_plan_item, meal_plan: meal_plan, scheduled_date: Date.today)
        allow_any_instance_of(MealPlanItem).to receive(:plannable).and_return(plannable)
        
        get api_v1_meal_plan_path(meal_plan), headers: headers
        json = JSON.parse(response.body)

        plannable_data = json['items_by_date'][Date.today.to_s].last['plannable']
        expect(plannable_data['title']).to eq("Test Title")
        expect(plannable_data['item_name']).to be_nil
        expect(plannable_data['quantity']).to eq(5)
      end

      it "handles plannable without quantity attribute (respond_to returns false)" do
        plannable = double("Plannable", id: 1)
        allow(plannable).to receive(:respond_to?).with(:title).and_return(true)
        allow(plannable).to receive(:respond_to?).with(:item_name).and_return(true)
        allow(plannable).to receive(:respond_to?).with(:quantity).and_return(false)
        allow(plannable).to receive(:title).and_return("Test Title")
        allow(plannable).to receive(:item_name).and_return("Test Item")
        
        item_without_quantity = create(:meal_plan_item, meal_plan: meal_plan, scheduled_date: Date.today)
        allow_any_instance_of(MealPlanItem).to receive(:plannable).and_return(plannable)
        
        get api_v1_meal_plan_path(meal_plan), headers: headers
        json = JSON.parse(response.body)

        plannable_data = json['items_by_date'][Date.today.to_s].last['plannable']
        expect(plannable_data['title']).to eq("Test Title")
        expect(plannable_data['item_name']).to eq("Test Item")
        expect(plannable_data['quantity']).to be_nil
      end
    end

    context "when meal plan has no items and no comments" do
      let!(:empty_meal_plan) { create(:meal_plan, user: user) }

      it "returns meal plan with empty items and comments" do
        get api_v1_meal_plan_path(empty_meal_plan), headers: headers
        json = JSON.parse(response.body)

        expect(json['meal_plan']['id']).to eq(empty_meal_plan.id)
        expect(json['comments']).to eq([])
        expect(json['items_by_date']).to eq({})
      end
    end

    context "when meal plan is not found" do
      it "returns 404 not found" do
        get api_v1_meal_plan_path(99999), headers: headers
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when unauthenticated" do
      it "returns 401 unauthorized" do
        get api_v1_meal_plan_path(meal_plan)
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE /api/v1/meal_plans/:id" do
    let!(:meal_plan) { create(:meal_plan, user: user) }

    context "when authenticated as the owner" do
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

    context "when unauthenticated" do
      it "returns 401 unauthorized" do
        delete api_v1_meal_plan_path(meal_plan)
        expect(response).to have_http_status(:unauthorized)
      end

      it "does not destroy the meal plan" do
        expect {
          delete api_v1_meal_plan_path(meal_plan)
        }.not_to change(MealPlan, :count)
      end
    end

    context "when meal plan does not exist" do
      it "returns 404 not found" do
        delete api_v1_meal_plan_path(99999), headers: headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end