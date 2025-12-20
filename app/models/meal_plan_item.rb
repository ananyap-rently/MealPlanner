class MealPlanItem < ApplicationRecord
  belongs_to :meal_plan
  belongs_to :plannable, polymorphic: true

  enum :meal_slot, {breakfast: 0, lunch: 1, dinner: 2, snack: 3}
  validates :scheduled_date, presence: true
  validates :meal_slot, presence: true
  # validates :plannable_type, inclusion: {in: %w[Recipe]}
  def plannable_name
    return "Unknown" if plannable.nil?
    plannable.respond_to?(:title) ? plannable.title : plannable.item_name
  end
end
