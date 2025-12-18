class MealPlan < ApplicationRecord
  belongs_to :user
  has_many :meal_plan_items
  has_many :shopping_list_items
end
