class Item < ApplicationRecord
    has_many :meal_plan_items, as: :plannable
    has_many :shopping_list_items, as: :purchasable
    validates :item_name, presence: true

    def self.ransackable_attributes(auth_object = nil)
        ["id", "item_name", "quantity", "created_at"]
    end

    def self.ransackable_associations(auth_object = nil)
        []
    end
end
