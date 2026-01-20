require 'rails_helper'

RSpec.describe "ShoppingListItems", type: :request do
  let(:user) { create(:user) }
  let(:item) { create(:item) }
  let(:ingredient) { create(:ingredient) }
  
  before { sign_in user }

describe "GET /index" do
  it "renders a successful response" do
    shopping_item = create(:shopping_list_item, user: user, purchasable: item)

    get shopping_list_items_path

    expect(response).to be_successful
    expect(user.shopping_list_items).to include(shopping_item)
  end
end


  describe "POST /create" do
    context "with an existing shopping list item (Merging)" do
      it "updates the quantity of the existing unpurchased item" do
        existing = create(:shopping_list_item, user: user, purchasable: item, quantity: "2", is_purchased: false)
        
        expect {
          post shopping_list_items_path, params: { 
            shopping_list_item: { item_type: 'existing_item', item_id: item.id, quantity: "3" } 
          }
        }.not_to change(ShoppingListItem, :count)

        existing.reload
        expect(existing.quantity).to eq(5.0)
        expect(response).to redirect_to(shopping_list_items_path)
        expect(flash[:notice]).to match(/merged/)
      end
    end

    context "with a new shopping list item" do
      it "creates a new item for an existing ingredient" do
        expect {
          post shopping_list_items_path, params: { 
            shopping_list_item: { item_type: 'existing_ingredient', ingredient_id: ingredient.id, quantity: "1" } 
          }
        }.to change(ShoppingListItem, :count).by(1)
      end

      it "creates a new Item via manual_item name" do
        expect {
          post shopping_list_items_path, params: { 
            shopping_list_item: { item_type: 'manual_item', manual_name: 'Milk', quantity: "1" } 
          }
        }.to change(Item, :count).by(1)
      end

      it "creates a new Ingredient via manual_ingredient name" do
        expect {
          post shopping_list_items_path, params: { 
            shopping_list_item: { item_type: 'manual_ingredient', manual_name: 'Salt', quantity: "1" } 
          }
        }.to change(Ingredient, :count).by(1)
      end
    end

    context "with invalid parameters" do
      it "redirects with alert if purchasable is nil (e.g., empty manual name)" do
        post shopping_list_items_path, params: { 
          shopping_list_item: { item_type: 'manual_item', manual_name: '', quantity: "1" } 
        }
        expect(flash[:alert]).to eq("Please select or enter an item.")
      end

      it "handles save failures (mocked)" do
        allow_any_instance_of(ShoppingListItem).to receive(:save).and_return(false)
        post shopping_list_items_path, params: { 
          shopping_list_item: { item_type: 'existing_item', item_id: item.id, quantity: "1" } 
        }
        expect(flash[:alert]).to eq("Failed to add item.")
      end
    end
  end

  describe "PATCH /update" do
    let!(:shopping_list_item) { create(:shopping_list_item, user: user) }

    it "updates the item" do
      patch shopping_list_item_path(shopping_list_item), params: { 
        shopping_list_item: { is_purchased: true } 
      }
      expect(shopping_list_item.reload.is_purchased).to be true
      expect(response).to redirect_to(shopping_list_items_path)
    end

    it "handles update failure" do
      allow_any_instance_of(ShoppingListItem).to receive(:update).and_return(false)
      patch shopping_list_item_path(shopping_list_item), params: { shopping_list_item: { quantity: "0" } }
      expect(flash[:alert]).to eq("Failed to update item.")
    end
  end

  describe "DELETE /destroy" do
    let!(:shopping_list_item) { create(:shopping_list_item, user: user) }

    it "destroys the requested item" do
      expect {
        delete shopping_list_item_path(shopping_list_item)
      }.to change(ShoppingListItem, :count).by(-1)
      expect(response).to redirect_to(shopping_list_items_path)
    end
  end

  describe "DELETE /clear_purchased" do
    it "removes only purchased items" do
      create(:shopping_list_item, user: user, is_purchased: true)
      create(:shopping_list_item, user: user, is_purchased: false)

      expect {
        delete clear_purchased_shopping_list_items_path
      }.to change(ShoppingListItem, :count).by(-1)
      
      expect(user.shopping_list_items.count).to eq(1)
      expect(response).to redirect_to(shopping_list_items_path)
    end
  end
end