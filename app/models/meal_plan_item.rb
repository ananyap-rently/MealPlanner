class MealPlanItem < ApplicationRecord
  belongs_to :meal_plan
  belongs_to :plannable, polymorphic: true

  has_one :user, through: :meal_plan

  enum :meal_slot, {breakfast: 0, lunch: 1, dinner: 2, snack: 3}
  validates :scheduled_date, presence: true
  validates :meal_slot, presence: true

  def plannable_name
    return "Unknown" if plannable.nil?
    plannable.respond_to?(:title) ? plannable.title : plannable.item_name
  end

  def self.ransackable_attributes(auth_object = nil)
    ["id", "meal_slot", "scheduled_date", "plannable_type", "plannable_id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["meal_plan", "plannable"]
  end
end
