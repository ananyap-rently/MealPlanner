class CreateShoppingListItems < ActiveRecord::Migration[8.1]
  def change
    create_table :shopping_list_items do |t|
      t.references :user, null: false, foreign_key: true
      t.references :purchasable, polymorphic: true, null: false
      t.decimal :quantity
      t.boolean :is_purchased

      t.timestamps
    end
     add_index :shopping_list_items, [:user_id, :is_purchased]
    add_index :shopping_list_items, [:user_id, :purchasable_type, :purchasable_id], 
              name: 'index_shopping_list_items_on_user_and_purchasable'
  end
end
