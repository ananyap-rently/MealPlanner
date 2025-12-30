class ShoppingListItem < ApplicationRecord
  belongs_to :user
  belongs_to :meal_plan, optional: true
  belongs_to :purchasable, polymorphic: true

  has_one :payment, dependent: :destroy
  scope :pending, -> {where(is_purchased: false)}
  def self.ransackable_attributes(auth_object = nil)
  ["id", "user_id", "purchasable_id", "purchasable_type", "quantity", "is_purchased", "meal_plan_id", "created_at"]
  end
  def self.ransackable_associations(auth_object = nil)
    ["user", "meal_plan", "purchasable"]
  end
end
