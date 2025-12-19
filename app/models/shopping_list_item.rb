class ShoppingListItem < ApplicationRecord
  belongs_to :user
  belongs_to :purchasable, polymorphic: true

  scope :pending, -> {where(is_purchased: false)}
end
