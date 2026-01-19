require 'rails_helper'

RSpec.describe "Api::V1::MealPlanItems", type: :request do
  let(:user) { create(:user) }
  let(:token) { create(:doorkeeper_access_token, resource_owner_id: user.id) }
  let(:headers) { { "Authorization" => "Bearer #{token.token}", "Accept" => "application/json" } }
  let(:meal_plan) { create(:meal_plan, user: user) }
  let(:recipe) { create(:recipe, title: "Pasta Carbonara") }

  describe "POST /api/v1/meal_plans/:meal_plan_id/meal_plan_items" do
    context "with valid Recipe params" do
      let(:params) do
        {
          meal_plan_item: {
            scheduled_date: Date.today,
            meal_slot: "dinner",
            plannable_type: "Recipe",
            plannable_id: recipe.id
          }
        }
      end

      it "returns the specific meal_plan_item_json structure" do
        post api_v1_meal_plan_meal_plan_items_path(meal_plan), params: params, headers: headers
        json = JSON.parse(response.body)

        expect(response).to have_http_status(:created)
        expect(json['meal_plan_item']).to include(
          'meal_slot' => 'dinner',
          'plannable_type' => 'Recipe'
        )
        expect(json['meal_plan_item']['plannable']['title']).to eq("Pasta Carbonara")
      end
    end

    context "with 'Item' type and on-the-fly creation" do
  let(:params) do
    {
      meal_plan_item: {
        scheduled_date: Date.today,
        meal_slot: "lunch",
        plannable_type: "Item"
      },
      new_item_name: "Greek Yogurt",
      new_item_quantity: "500.0"
    }
  end

  it "creates a new Item record and returns Item-specific JSON" do
    expect {
      post api_v1_meal_plan_meal_plan_items_path(meal_plan), params: params, headers: headers
    }.to change(Item, :count).by(1)

    json = JSON.parse(response.body)
    expect(response).to have_http_status(:created)
    
    # Check the meal_plan_item structure
    expect(json['meal_plan_item']).to be_present
    expect(json['meal_plan_item']['plannable_type']).to eq('Item')
    
    # Check the plannable (Item) details
    plannable = json['meal_plan_item']['plannable']
    expect(plannable['item_name']).to eq('Greek Yogurt')
    expect(plannable['quantity']).to eq("500.0")
  end
end
    context "with invalid params" do
      it "returns unprocessable_entity and error messages" do
        # Sending empty params to trigger validation failure
        post api_v1_meal_plan_meal_plan_items_path(meal_plan), 
             params: { meal_plan_item: { meal_slot: nil } }, 
             headers: headers
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to have_key('errors')
      end
    end
  end

  describe "POST /api/v1/meal_plans/:meal_plan_id/meal_plan_items/add_to_shopping_list" do
    context "when plannable is an Item" do
      let!(:standalone_item) { create(:item, item_name: "Protein Shake", quantity: "1.0") }
      let!(:meal_item) { create(:meal_plan_item, meal_plan: meal_plan, plannable: standalone_item) }

      it "adds the standalone item to shopping list" do
        expect {
          post add_to_shopping_list_api_v1_meal_plan_meal_plan_items_path(meal_plan), headers: headers
        }.to change(user.shopping_list_items, :count).by(1)
        
        expect(user.shopping_list_items.last.purchasable).to eq(standalone_item)
      end

      it "merges standalone items if they already exist in the shopping list" do
        create(:shopping_list_item, user: user, purchasable: standalone_item, quantity: "2.0", is_purchased: false)
        
        post add_to_shopping_list_api_v1_meal_plan_meal_plan_items_path(meal_plan), headers: headers
        
        json = JSON.parse(response.body)
        expect(json['merged_count']).to eq(1)
        # 2.0 (existing) + 1.0 (from meal plan item) = 3.0
        expect(user.shopping_list_items.find_by(purchasable: standalone_item).quantity.to_f).to eq(3.0)
      end
    end

    context "with a Recipe containing ingredients" do
      let!(:ingredient) { create(:ingredient, name: "Cheddar") } 
      let!(:recipe_with_ing) { create(:recipe) }
      let!(:ri) { create(:recipe_ingredient, recipe: recipe_with_ing, ingredient: ingredient, quantity: 100.0, unit: "g") }
      let!(:meal_item) { create(:meal_plan_item, meal_plan: meal_plan, plannable: recipe_with_ing) }

      it "adds recipe ingredients to the user's shopping list" do
        post add_to_shopping_list_api_v1_meal_plan_meal_plan_items_path(meal_plan), headers: headers
        expect(user.shopping_list_items.last.purchasable).to eq(ingredient)
      end

      it "merges quantities for recipe ingredients" do
        create(:shopping_list_item, user: user, purchasable: ingredient, quantity: 50.0, is_purchased: false)
        post add_to_shopping_list_api_v1_meal_plan_meal_plan_items_path(meal_plan), headers: headers
        expect(user.shopping_list_items.find_by(purchasable: ingredient).quantity.to_f).to eq(150.0)
      end
    end
  end

  describe "DELETE /api/v1/meal_plans/:meal_plan_id/meal_plan_items/:id" do
    let!(:meal_item) { create(:meal_plan_item, meal_plan: meal_plan, plannable: recipe) }
    
    it "removes the item and returns the plannable title in the message" do
      delete api_v1_meal_plan_meal_plan_item_path(meal_plan, meal_item), headers: headers
      
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['message']).to eq("Pasta Carbonara removed from plan")
    end
  end
end