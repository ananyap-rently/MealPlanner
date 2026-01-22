require 'rails_helper'

RSpec.describe "Admin::ShoppingListItems", type: :request do
  let(:admin_user) { AdminUser.create!(email: 'admin@example.com', password: 'password') }
  let(:user) { create(:user) }
  let(:item) { create(:item, item_name: "Milk") }
  let(:ingredient) { create(:ingredient, name: "Flour") }

  before do
    # Authenticate admin (Assuming Devise)
    sign_in admin_user
  end

  describe "GET /admin/shopping_list_items" do
    let!(:manual_item) { create(:shopping_list_item, :for_item, user: user, meal_plan: nil) }
    let!(:meal_plan_item) { create(:shopping_list_item, :for_ingredient, user: user, is_purchased: true).tap { |s| s.update(meal_plan: create(:meal_plan)) } }

    # it "renders the index page and covers all branch logic" do
    #   get admin_shopping_list_items_path
    #   expect(response).to have_http_status(:success)
      
    #   # Verifies "Source" column branch (Manual Entry vs Meal Plan link)
    #   expect(response.body).to include("Manual Entry")
    #   expect(response.body).to include("Meal Plan ##{meal_plan_item.meal_plan_id}")

    #   # Verifies "Purchasable" column branch (Item vs Ingredient)
    #   expect(response.body).to include("Milk")
    #   expect(response.body).to include("Flour")
    # end

    it "tests scopes" do
      get admin_shopping_list_items_path(scope: 'pending')
      expect(response.body).to include(manual_item.id.to_s)
      
      get admin_shopping_list_items_path(scope: 'purchased')
      expect(response.body).to include(meal_plan_item.id.to_s)
    end
  end

  describe "GET /admin/shopping_list_items/new" do
    it "renders the form" do
      get new_admin_shopping_list_item_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/shopping_list_items" do
    context "with valid params" do
      let(:valid_attributes) {
        {
          shopping_list_item: {
            user_id: user.id,
            purchasable_type: "Item",
            purchasable_id: item.id,
            quantity: 2,
            is_purchased: false
          }
        }
      }

      it "creates a new ShoppingListItem" do
        expect {
          post admin_shopping_list_items_path, params: valid_attributes
        }.to change(ShoppingListItem, :count).by(1)
        expect(response).to redirect_to(admin_shopping_list_item_path(ShoppingListItem.last))
      end
    end
  end

  describe "GET /admin/shopping_list_items/:id/edit" do
    let(:sli) { create(:shopping_list_item, :for_item, user: user) }
    
    it "renders the edit page" do
      get edit_admin_shopping_list_item_path(sli)
      expect(response).to have_http_status(:success)
    end
  end

  describe "Edge Case: Deleted Record for Purchasable" do
    let!(:ghost_sli) { create(:shopping_list_item, user: user, purchasable_type: "Item", purchasable_id: 99999) }

    # it "renders 'Deleted record' when purchasable is missing" do
    #   # This hits the '|| "Deleted record"' branch in your index column
    #   get admin_shopping_list_items_path
    #   expect(response.body).to include("Deleted record")
    # end
  end
end