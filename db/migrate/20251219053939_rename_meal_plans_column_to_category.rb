class RenameMealPlansColumnToCategory < ActiveRecord::Migration[8.1]
  def change
    rename_column :meal_plans, :name, :category
  end
end
