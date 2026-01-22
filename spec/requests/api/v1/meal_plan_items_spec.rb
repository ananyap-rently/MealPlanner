require 'rails_helper'

RSpec.describe "Api::V1::MealPlanItems", type: :request do
  let(:user) { create(:user) }
  let(:token) { create(:doorkeeper_access_token, resource_owner_id: user.id) }
  let(:headers) { { "Authorization" => "Bearer #{token.token}", "Accept" => "application/json" } }
  let(:meal_plan) { create(:meal_plan, user: user) }
  let(:recipe) { create(:recipe, title: "Pasta Carbonara") }

  # describe "GET /api/v1/meal_plans/:meal_plan_id/meal_plan_items" do
  #   let!(:meal_item1) { create(:meal_plan_item, meal_plan: meal_plan, plannable: recipe, scheduled_date: Date.today, meal_slot: "dinner") }
  #   let!(:meal_item2) { create(:meal_plan_item, meal_plan: meal_plan, plannable: recipe, scheduled_date: Date.tomorrow, meal_slot: "lunch") }

  #   it "returns all meal plan items ordered by scheduled_date and meal_slot" do
  #     get api_v1_meal_plan_meal_plan_items_path(meal_plan), headers: headers
  #     expect(response).to have_http_status(:ok)
  #     json = JSON.parse(response.body)
  #     expect(json['meal_plan_items'].count).to eq(2)
  #     expect(json['meal_plan_items'].first['id']).to eq(meal_item1.id)
  #   end
  # end

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

    context "with Recipe that doesn't exist" do
      let(:params) do
        {
          meal_plan_item: {
            scheduled_date: Date.today,
            meal_slot: "dinner",
            plannable_type: "Recipe",
            plannable_id: 99999
          }
        }
      end

      it "returns unprocessable_content when recipe doesn't exist" do
        post api_v1_meal_plan_meal_plan_items_path(meal_plan), params: params, headers: headers
        
        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)).to have_key('errors')
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
        
        expect(json['meal_plan_item']).to be_present
        expect(json['meal_plan_item']['plannable_type']).to eq('Item')
        
        plannable = json['meal_plan_item']['plannable']
        expect(plannable['item_name']).to eq('Greek Yogurt')
        expect(plannable['quantity']).to eq("500.0")
      end
    end

    context "with 'Item' type and new_item_name with whitespace" do
      let(:params) do
        {
          meal_plan_item: {
            scheduled_date: Date.today,
            meal_slot: "lunch",
            plannable_type: "Item"
          },
          new_item_name: "  Greek Yogurt  ",
          new_item_quantity: "  500.0  "
        }
      end

      it "strips whitespace from item name and quantity" do
        post api_v1_meal_plan_meal_plan_items_path(meal_plan), params: params, headers: headers
        json = JSON.parse(response.body)

        expect(response).to have_http_status(:created)
        plannable = json['meal_plan_item']['plannable']
        expect(plannable['item_name']).to eq('Greek Yogurt')
        expect(plannable['quantity']).to eq("500.0")
      end
    end

    context "with 'Item' type and existing item name" do
      let!(:existing_item) { create(:item, item_name: "Greek Yogurt", quantity: "200.0") }
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

      it "updates existing item quantity" do
        expect {
          post api_v1_meal_plan_meal_plan_items_path(meal_plan), params: params, headers: headers
        }.not_to change(Item, :count)

        json = JSON.parse(response.body)
        expect(response).to have_http_status(:created)
        
        plannable = json['meal_plan_item']['plannable']
        expect(plannable['quantity']).to eq("500.0")
      end
    end

    context "with 'Item' type and new_item_name without quantity" do
      let(:params) do
        {
          meal_plan_item: {
            scheduled_date: Date.today,
            meal_slot: "lunch",
            plannable_type: "Item"
          },
          new_item_name: "Greek Yogurt"
        }
      end

      it "creates item without setting quantity" do
        post api_v1_meal_plan_meal_plan_items_path(meal_plan), params: params, headers: headers
        json = JSON.parse(response.body)

        expect(response).to have_http_status(:created)
        expect(json['meal_plan_item']['plannable']['item_name']).to eq('Greek Yogurt')
      end
    end

    context "with 'Item' type and plannable_id (existing item)" do
      let!(:existing_item) { create(:item, item_name: "Existing Item", quantity: "100.0") }
      let(:params) do
        {
          meal_plan_item: {
            scheduled_date: Date.today,
            meal_slot: "lunch",
            plannable_type: "Item",
            plannable_id: existing_item.id
          }
        }
      end

      it "uses existing item by id" do
        post api_v1_meal_plan_meal_plan_items_path(meal_plan), params: params, headers: headers
        json = JSON.parse(response.body)

        expect(response).to have_http_status(:created)
        expect(json['meal_plan_item']['plannable']['item_name']).to eq('Existing Item')
      end
    end

    context "with 'Item' type and invalid plannable_id" do
      let(:params) do
        {
          meal_plan_item: {
            scheduled_date: Date.today,
            meal_slot: "lunch",
            plannable_type: "Item",
            plannable_id: 99999
          }
        }
      end

      it "returns unprocessable_content when item doesn't exist" do
        post api_v1_meal_plan_meal_plan_items_path(meal_plan), params: params, headers: headers
        
        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)).to have_key('errors')
      end
    end

    context "with invalid params" do
      it "returns unprocessable_content and error messages" do
        post api_v1_meal_plan_meal_plan_items_path(meal_plan), 
             params: { meal_plan_item: { meal_slot: nil } }, 
             headers: headers
        
        expect(response).to have_http_status(:unprocessable_content)
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
        json = JSON.parse(response.body)
        expect(json['added_count']).to eq(1)
        expect(json['merged_count']).to eq(0)
        expect(json['message']).to eq("1 new items added")
      end

      it "merges standalone items if they already exist in the shopping list" do
        create(:shopping_list_item, user: user, purchasable: standalone_item, quantity: "2.0", is_purchased: false)
        
        post add_to_shopping_list_api_v1_meal_plan_meal_plan_items_path(meal_plan), headers: headers
        
        json = JSON.parse(response.body)
        expect(json['merged_count']).to eq(1)
        expect(json['added_count']).to eq(0)
        expect(json['message']).to eq("1 items merged")
        expect(user.shopping_list_items.find_by(purchasable: standalone_item).quantity.to_f).to eq(3.0)
      end
    end

    context "when plannable is an Item without quantity" do
      let!(:standalone_item) { create(:item, item_name: "Protein Shake", quantity: nil) }
      let!(:meal_item) { create(:meal_plan_item, meal_plan: meal_plan, plannable: standalone_item) }

      it "adds item with default quantity of 1" do
        post add_to_shopping_list_api_v1_meal_plan_meal_plan_items_path(meal_plan), headers: headers
        
        shopping_item = user.shopping_list_items.last
        expect(shopping_item.quantity.to_f).to eq(1.0)
      end
    end

    context "with a Recipe containing ingredients" do
      let!(:ingredient) { create(:ingredient, name: "Cheddar") } 
      let!(:recipe_with_ing) { create(:recipe) }
      let!(:ri) { create(:recipe_ingredient, recipe: recipe_with_ing, ingredient: ingredient, quantity: 100.0, unit: "g") }
      let!(:meal_item) { create(:meal_plan_item, meal_plan: meal_plan, plannable: recipe_with_ing) }

      it "adds recipe ingredients to the user's shopping list" do
        expect {
          post add_to_shopping_list_api_v1_meal_plan_meal_plan_items_path(meal_plan), headers: headers
        }.to change(user.shopping_list_items, :count).by(1)
        
        expect(user.shopping_list_items.last.purchasable).to eq(ingredient)
        json = JSON.parse(response.body)
        expect(json['added_count']).to eq(1)
        expect(json['message']).to eq("1 new items added")
      end

      it "merges quantities for recipe ingredients" do
        create(:shopping_list_item, user: user, purchasable: ingredient, quantity: "50.0 g", is_purchased: false)
        post add_to_shopping_list_api_v1_meal_plan_meal_plan_items_path(meal_plan), headers: headers
        
        shopping_item = user.shopping_list_items.find_by(purchasable: ingredient)
        expect(shopping_item.quantity.to_s.split.first.to_f).to eq(150.0)
        
        json = JSON.parse(response.body)
        expect(json['merged_count']).to eq(1)
        expect(json['message']).to eq("1 items merged")
      end
    end

    context "with multiple items and recipes" do
      let!(:standalone_item) { create(:item, item_name: "Protein Shake", quantity: "2.0") }
      let!(:ingredient1) { create(:ingredient, name: "Cheddar") } 
      let!(:ingredient2) { create(:ingredient, name: "Tomato") } 
      let!(:recipe_with_ing) { create(:recipe) }
      let!(:ri1) { create(:recipe_ingredient, recipe: recipe_with_ing, ingredient: ingredient1, quantity: 100.0, unit: "g") }
      let!(:ri2) { create(:recipe_ingredient, recipe: recipe_with_ing, ingredient: ingredient2, quantity: 200.0, unit: "g") }
      let!(:meal_item1) { create(:meal_plan_item, meal_plan: meal_plan, plannable: standalone_item) }
      let!(:meal_item2) { create(:meal_plan_item, meal_plan: meal_plan, plannable: recipe_with_ing) }

      it "adds both items and recipe ingredients" do
        expect {
          post add_to_shopping_list_api_v1_meal_plan_meal_plan_items_path(meal_plan), headers: headers
        }.to change(user.shopping_list_items, :count).by(3)
        
        json = JSON.parse(response.body)
        expect(json['added_count']).to eq(3)
        expect(json['merged_count']).to eq(0)
        expect(json['message']).to eq("3 new items added")
      end

      it "handles mixed adding and merging" do
        create(:shopping_list_item, user: user, purchasable: ingredient1, quantity: "50.0 g", is_purchased: false)
        
        post add_to_shopping_list_api_v1_meal_plan_meal_plan_items_path(meal_plan), headers: headers
        
        json = JSON.parse(response.body)
        expect(json['added_count']).to eq(2)
        expect(json['merged_count']).to eq(1)
        expect(json['message']).to eq("2 new items added, 1 items merged")
      end
    end

    context "with no items to add" do
      it "returns default message" do
        post add_to_shopping_list_api_v1_meal_plan_meal_plan_items_path(meal_plan), headers: headers
        
        json = JSON.parse(response.body)
        expect(json['message']).to eq("Shopping list updated")
        expect(json['added_count']).to eq(0)
        expect(json['merged_count']).to eq(0)
      end
    end
  end

  describe "DELETE /api/v1/meal_plans/:meal_plan_id/meal_plan_items/:id" do
    context "when plannable is a Recipe" do
      let!(:meal_item) { create(:meal_plan_item, meal_plan: meal_plan, plannable: recipe) }
      
      it "removes the item and returns the recipe title in the message" do
        delete api_v1_meal_plan_meal_plan_item_path(meal_plan, meal_item), headers: headers
        
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['message']).to eq("Pasta Carbonara removed from plan")
      end
    end

    context "when plannable is an Item" do
      let!(:standalone_item) { create(:item, item_name: "Protein Shake") }
      let!(:meal_item) { create(:meal_plan_item, meal_plan: meal_plan, plannable: standalone_item) }
      
      it "removes the item and returns the item name in the message" do
        delete api_v1_meal_plan_meal_plan_item_path(meal_plan, meal_item), headers: headers
        
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['message']).to eq("Protein Shake removed from plan")
      end
    end
  end
end