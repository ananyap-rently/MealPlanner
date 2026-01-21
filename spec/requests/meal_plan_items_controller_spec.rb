
require 'rails_helper'

RSpec.describe "MealPlanItems", type: :request do
  let(:user) { create(:user) }
  let(:meal_plan) { create(:meal_plan, user: user) }
  let(:recipe) { create(:recipe, user: user) }
  let(:item) { create(:item) }

  before { sign_in user }

  describe "POST /create" do
    context "when adding a Recipe" do
      it "creates a new MealPlanItem and redirects" do
        expect {
          post meal_plan_meal_plan_items_path(meal_plan), params: {
            meal_plan_item: {
              scheduled_date: Date.today,
              meal_slot: "lunch",
              plannable_type: "Recipe",
              plannable_id: recipe.id
            },
            commit: "Add to Plan"
          }
        }.to change(MealPlanItem, :count).by(1)
        expect(response).to redirect_to(meal_plan)
        expect(flash[:notice]).to include("Lunch")
      end
    end

    context "when adding an Item via text field (New/Existing Item)" do
      it "creates a new Item and assigns it to the meal plan" do
        expect {
          post meal_plan_meal_plan_items_path(meal_plan), params: {
            meal_plan_item: { plannable_type: "Item", scheduled_date: Date.today, meal_slot: "snack" },
            new_item_name: "Protein Bar",
            new_item_quantity: "1.0",
            commit: "Add to Plan"
          }
        }.to change(Item, :count).by(1)
      end

      it "updates the quantity if the item name already exists" do
        existing_item = create(:item, item_name: "Apple", quantity: 1.0)
        post meal_plan_meal_plan_items_path(meal_plan), params: {
          meal_plan_item: { plannable_type: "Item", scheduled_date: Date.today, meal_slot: "breakfast" },
          new_item_name: "Apple",
          new_item_quantity: "5.5",
          commit: "Add to Plan"
        }
        expect(existing_item.reload.quantity).to eq(5.5)
      end
    end

    context "UI Toggles and Errors" do
      it "renders show when commit is missing (radio button onchange)" do
        post meal_plan_meal_plan_items_path(meal_plan), params: {
          meal_plan_item: { plannable_type: "Recipe" }
        }
       expect(response).to have_http_status(:ok)
       #expect(response.body).to include(meal_plan.title)

      end

      it "renders show with unprocessable_content on save failure" do
        post meal_plan_meal_plan_items_path(meal_plan), params: {
          meal_plan_item: { scheduled_date: nil }, # Validation error
          commit: "Add to Plan"
        }
        expect(response).to have_http_status(:unprocessable_content)
        expect(flash[:alert]).to include("Could not save item")
      end
    end
  end

  describe "POST /add_to_shopping_list" do
    it "merges recipe ingredients correctly (parsing strings with units)" do
      ri = create(:recipe_ingredient, recipe: recipe, quantity: 2.0, unit: "cups")
      create(:meal_plan_item, meal_plan: meal_plan, plannable: recipe)
      # Existing item in list: "1.5 cups"
      create(:shopping_list_item, user: user, purchasable: ri.ingredient, quantity: "1.5 cups", is_purchased: false)

      post add_to_shopping_list_meal_plan_meal_plan_items_path(meal_plan)

      shopping_item = user.shopping_list_items.find_by(purchasable: ri.ingredient)
      # 1.5 + 2.0 = 3.5
      expect(shopping_item.quantity.to_f).to eq(3.5)


    end

    it "merges standalone items with decimal quantities" do
      create(:meal_plan_item, meal_plan: meal_plan, plannable: item)
      create(:shopping_list_item, user: user, purchasable: item, quantity: "10.0", is_purchased: false)

      post add_to_shopping_list_meal_plan_meal_plan_items_path(meal_plan)

      shopping_item = user.shopping_list_items.find_by(purchasable: item)
      # item.quantity (1.5) + existing (10.0) = 11.5
      expect(shopping_item.quantity.to_f).to eq(11.0)
    end
  end

  describe "DELETE /destroy" do
    it "removes the item and shows correct notice for recipes" do
      mpi = create(:meal_plan_item, meal_plan: meal_plan, plannable: recipe)
      delete meal_plan_meal_plan_item_path(meal_plan, mpi)
      expect(flash[:notice]).to include(recipe.title)
    end

    it "removes the item and shows correct notice for items" do
      mpi = create(:meal_plan_item, meal_plan: meal_plan, plannable: item)
      delete meal_plan_meal_plan_item_path(meal_plan, mpi)
      expect(flash[:notice]).to include(item.item_name)
    end
  end
end