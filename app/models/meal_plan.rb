class MealPlan < ApplicationRecord
  belongs_to :user
  has_many :meal_plan_items, dependent: :destroy
  has_many :shopping_list_items, dependent: :destroy
  has_many :recipes, through: :meal_plan_items, source: :plannable, source_type: 'Recipe'
  has_many :comments, as: :commentable, dependent: :destroy
  validates :category, presence: true
  validates :start_date, presence: true

  # Returns end date (start_date + 6 days for a week)
  def end_date
    start_date + 6.days
  end

  # Returns all dates in the week
  def week_dates
  # Generates an array of dates from start to end (usually 7 days)
  (start_date..start_date + 6.days).to_a
end

  def self.ransackable_attributes(auth_object = nil)
    ["id", "category", "start_date", "user_id", "created_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["user", "meal_plan_items","shopping_list_items"]
  end
end

