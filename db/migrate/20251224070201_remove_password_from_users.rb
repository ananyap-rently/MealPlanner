class RemovePasswordFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :password, :string if column_exists?(:users, :password)
  end
end
