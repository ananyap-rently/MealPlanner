class ShoppingListItem < ApplicationRecord
  belongs_to :user
  belongs_to :meal_plan, optional: true
  belongs_to :purchasable, polymorphic: true

  has_one :payment, dependent: :destroy
  scope :pending, -> {where(is_purchased: false)}
end
