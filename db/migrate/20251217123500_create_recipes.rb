class CreateRecipes < ActiveRecord::Migration[8.1]
  def change
    create_table :recipes do |t|
      t.string :title
      t.text :instructions
      t.decimal :prep_time
      t.decimal :servings
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
