# # spec/factories/meal_plans.rb
FactoryBot.define do
  factory :meal_plan do
    association :user
    category { "Week #{rand(1..52)} Meal Plan" }
    start_date { Date.today }
    
  end
end
#