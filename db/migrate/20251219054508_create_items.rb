class CreateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :items do |t|
      t.string :item_name
      t.decimal :quantity

      t.timestamps
    end
     add_index :items, :item_name
  end
end
