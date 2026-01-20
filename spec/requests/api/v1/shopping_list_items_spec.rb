# spec/requests/api/v1/shopping_list_items_spec.rb
require 'rails_helper'

RSpec.describe "Api::V1::ShoppingListItems", type: :request do
  let(:user) { create(:user) }
  let(:token) { create(:doorkeeper_access_token, resource_owner_id: user.id) }
  let(:headers) { { "Authorization" => "Bearer #{token.token}", "Accept" => "application/json" } }
  
  let!(:item) { create(:item, item_name: "Milk") }
  let!(:ingredient) { create(:ingredient, name: "Sugar") }

  describe "GET /api/v1/shopping_list_items" do
    let!(:shopping_item) { create(:shopping_list_item, user: user, purchasable: item) }

    it "returns all shopping list items for current user" do
      get api_v1_shopping_list_items_path, headers: headers
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.size).to eq(2)
      
    end

    it "does not return other users' shopping items" do
      other_user = create(:user)
      create(:shopping_list_item, user: other_user, purchasable: item)
      
      get api_v1_shopping_list_items_path, headers: headers
      
      json = JSON.parse(response.body)
      expect(json.size).to eq(2) # Only current user's item
    end
  end

  describe "POST /api/v1/shopping_list_items" do
    context "with existing item" do
      let(:params) do
        {
          shopping_list_item: {
            item_type: "existing_item",
            item_id: item.id,
            quantity: "2.0"
          }
        }
      end

      it "creates a new shopping list item" do
        expect {
          post api_v1_shopping_list_items_path, params: params, headers: headers
        }.to change(user.shopping_list_items, :count).by(1)
        
        expect(response).to have_http_status(:created)
        expect(ShoppingListItem.last.purchasable).to eq(item)
      end

      it "merges quantities when item already exists" do
        create(:shopping_list_item, user: user, purchasable: item, quantity: 3.0, is_purchased: false)
        
        post api_v1_shopping_list_items_path, params: params, headers: headers
        
        expect(user.shopping_list_items.count).to eq(1)
        expect(user.shopping_list_items.first.quantity.to_f).to eq(5.0)
      end

      it "does not merge with purchased items" do
        create(:shopping_list_item, user: user, purchasable: item, quantity: 3.0, is_purchased: true)
        
        expect {
          post api_v1_shopping_list_items_path, params: params, headers: headers
        }.to change(user.shopping_list_items, :count).by(1)
      end
    end

    context "with existing ingredient" do
      let(:params) do
        {
          shopping_list_item: {
            item_type: "existing_ingredient",
            ingredient_id: ingredient.id,
            quantity: "100"
          }
        }
      end

      it "creates shopping list item with ingredient" do
        expect {
          post api_v1_shopping_list_items_path, params: params, headers: headers
        }.to change(user.shopping_list_items, :count).by(1)
        
        expect(ShoppingListItem.last.purchasable).to eq(ingredient)
      end
    end

    context "with manual item creation" do
      let(:params) do
        {
          shopping_list_item: {
            item_type: "manual_item",
            manual_name: "New Grocery Item",
            quantity: "1"
          }
        }
      end

      it "creates new item and shopping list entry" do
        expect {
          post api_v1_shopping_list_items_path, params: params, headers: headers
        }.to change(Item, :count).by(1).and change(ShoppingListItem, :count).by(1)
        
        expect(Item.last.item_name).to eq("New Grocery Item")
      end

      it "reuses existing item with same name" do
        existing = create(:item, item_name: "New Grocery Item")
        
        expect {
          post api_v1_shopping_list_items_path, params: params, headers: headers
        }.to change(Item, :count).by(0).and change(ShoppingListItem, :count).by(1)
        
        expect(ShoppingListItem.last.purchasable).to eq(existing)
      end

      it "returns error when manual_name is blank" do
        params[:shopping_list_item][:manual_name] = ""
        
        post api_v1_shopping_list_items_path, params: params, headers: headers
        
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']).to be_present
      end
    end

    context "with manual ingredient creation" do
      let(:params) do
        {
          shopping_list_item: {
            item_type: "manual_ingredient",
            manual_name: "Paprika",
            quantity: "50g"
          }
        }
      end

      it "creates new ingredient and shopping list entry" do
        expect {
          post api_v1_shopping_list_items_path, params: params, headers: headers
        }.to change(Ingredient, :count).by(1).and change(ShoppingListItem, :count).by(1)
        
        expect(Ingredient.last.name).to eq("Paprika")
      end
    end
  end

  describe "PATCH /api/v1/shopping_list_items/:id" do
    let!(:shopping_item) { create(:shopping_list_item, user: user, purchasable: item, is_purchased: false) }

    it "updates the shopping list item" do
      patch api_v1_shopping_list_item_path(shopping_item), 
            params: { shopping_list_item: { is_purchased: true, quantity: "5.0" } }, 
            headers: headers
      
      expect(response).to have_http_status(:ok)
      shopping_item.reload
      expect(shopping_item.is_purchased).to be true
      expect(shopping_item.quantity.to_f).to eq(5.0)
    end

    it "prevents updating other users' items" do
      other_user = create(:user)
      other_item = create(:shopping_list_item, user: other_user, purchasable: item)
      
      patch api_v1_shopping_list_item_path(other_item), 
            params: { shopping_list_item: { is_purchased: true } }, 
            headers: headers
      
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/v1/shopping_list_items/:id" do
    let!(:shopping_item) { create(:shopping_list_item, user: user, purchasable: item) }

    it "deletes the shopping list item" do
      expect {
        delete api_v1_shopping_list_item_path(shopping_item), headers: headers
      }.to change(user.shopping_list_items, :count).by(-1)
      
      expect(response).to have_http_status(:no_content)
    end

    it "prevents deleting other users' items" do
      other_user = create(:user)
      other_item = create(:shopping_list_item, user: other_user, purchasable: item)
      
      expect {
        delete api_v1_shopping_list_item_path(other_item), headers: headers
      }.not_to change(ShoppingListItem, :count)
      
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/v1/shopping_list_items/clear_purchased" do
    let!(:purchased_item) { create(:shopping_list_item, user: user, purchasable: item, is_purchased: true) }
    let!(:unpurchased_item) { create(:shopping_list_item, user: user, purchasable: ingredient, is_purchased: false) }

    it "clears only purchased items" do
      expect {
        delete clear_purchased_api_v1_shopping_list_items_path, headers: headers
      }.to change(user.shopping_list_items, :count).by(-1)
      
      expect(response).to have_http_status(:no_content)
      expect(user.shopping_list_items.exists?(unpurchased_item.id)).to be true
      expect(user.shopping_list_items.exists?(purchased_item.id)).to be false
    end

    it "does not affect other users' items" do
      other_user = create(:user)
      other_purchased = create(:shopping_list_item, user: other_user, purchasable: item, is_purchased: true)
      
      delete clear_purchased_api_v1_shopping_list_items_path, headers: headers
      
      expect(ShoppingListItem.exists?(other_purchased.id)).to be true
    end
  end

  describe "authorization" do
    it "requires authentication for all actions" do
      get api_v1_shopping_list_items_path
      expect(response).to have_http_status(:unauthorized)
      
      post api_v1_shopping_list_items_path
      expect(response).to have_http_status(:unauthorized)
    end
  end
end