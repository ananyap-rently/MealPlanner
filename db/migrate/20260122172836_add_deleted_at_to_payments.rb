class AddDeletedAtToPayments < ActiveRecord::Migration[8.1]
  def change
    add_column :payments, :deleted_at, :datetime
    add_index :payments, :deleted_at
  end
end
