class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :shopping_list_item, null: false, foreign_key: true
      t.string :payment_status

      t.timestamps
    end
  end
end
