class Item < ApplicationRecord
    has_many :meal_plan_items, as: :plannable
    has_many :shopping_list_items, as: :purchasable
    validates :item_name, presence: true
end
