# frozen_string_literal: true

class AddDeviseToUsers < ActiveRecord::Migration[8.1]
  def change
    # Only add fields that don't exist
    # Devise fields (if not already present)
    add_column :users, :encrypted_password, :string, null: false, default: "" unless column_exists?(:users, :encrypted_password)
    
    ## Recoverable
    add_column :users, :reset_password_token, :string unless column_exists?(:users, :reset_password_token)
    add_column :users, :reset_password_sent_at, :datetime unless column_exists?(:users, :reset_password_sent_at)

    ## Rememberable
    add_column :users, :remember_created_at, :datetime unless column_exists?(:users, :remember_created_at)

    # Add role if not exists
    add_column :users, :role, :integer, default: 0, null: false unless column_exists?(:users, :role)

    # Add indexes
    add_index :users, :email, unique: true unless index_exists?(:users, :email)
    add_index :users, :reset_password_token, unique: true unless index_exists?(:users, :reset_password_token)
  end
end
