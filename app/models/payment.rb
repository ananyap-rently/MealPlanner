class Payment < ApplicationRecord
  belongs_to :shopping_list_item
  has_one :user, through: :shopping_list_item

  validates :payment_status, presence: true, inclusion: { in: %w[pending completed] }
  

  scope :pending, -> { where(payment_status: 'pending') }
  scope :completed, -> { where(payment_status: 'completed') }
  after_update :mark_item_as_purchased, if: :saved_change_to_payment_status?

 
  def self.ransackable_attributes(auth_object = nil)
    ["id","shopping_list_item_id", "payment_status"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["shopping_list_item"]
  end
  def item_name
    case shopping_list_item.purchasable_type 
    when "Item"
      shopping_list_item.purchasable.item_name
    when "Ingredient"
      shopping_list_item.purchasable.name
    else
      "Unknown Item"
    end
  end

  private

  def mark_item_as_purchased
    if payment_status == "completed"
      shopping_list_item.update(is_purchased: true)
    elsif payment_status == "pending"
      shopping_list_item.update(is_purchased: false)
    end
  end
end