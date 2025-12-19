class CreateMealPlanItems < ActiveRecord::Migration[8.1]
  def change
    create_table :meal_plan_items do |t|
      t.references :meal_plan, null: false, foreign_key: true
      t.references :plannable, polymorphic: true, null: false
      t.date :scheduled_date
      t.string :meal_slot

      t.timestamps
    end
     add_index :meal_plan_items, [:meal_plan_id, :scheduled_date, :meal_slot]
  end
end
