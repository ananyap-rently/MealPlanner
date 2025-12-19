class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.references :user, null: false, foreign_key: true
      t.text :content
      t.references :commentable, polymorphic: true, null: false

      t.timestamps
    end
    add_index :comments, [:meal_plan_id, :created_at]
  end
end
