class CreateMealPlans < ActiveRecord::Migration[8.1]
  def change
    create_table :meal_plans do |t|
      t.string :name
      t.date :start_date
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    add_index :meal_plans, [:user_id, :start_date]
  end
end
