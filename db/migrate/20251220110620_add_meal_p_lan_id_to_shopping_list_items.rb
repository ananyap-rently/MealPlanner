class AddMealPLanIdToShoppingListItems < ActiveRecord::Migration[8.1]
   def change
    add_reference :shopping_list_items, :meal_plan, foreign_key: true, null: true
  end
end
