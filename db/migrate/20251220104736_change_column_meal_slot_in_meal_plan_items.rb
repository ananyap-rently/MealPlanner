class ChangeColumnMealSlotInMealPlanItems < ActiveRecord::Migration[8.1]
 def change
    # First, clear existing data to avoid conversion issues
    reversible do |dir|
      dir.up do
        MealPlanItem.update_all(meal_slot: nil)
      end
    end
    
    # Change column type from string to integer
    change_column :meal_plan_items, :meal_slot, :integer, using: 'meal_slot::integer'
  end
end
