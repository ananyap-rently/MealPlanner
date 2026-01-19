# # spec/factories/meal_plans.rb
FactoryBot.define do
  factory :meal_plan do
    association :user
    category { "Week #{rand(1..52)} Meal Plan" }
    start_date { Date.today }
    # end_date { Date.today + 7.days }
    # Add any other required fields based on your schema
  end
end
# spec/factories/meal_plans.rb
# FactoryBot.define do
#   factory :meal_plan do
#     association :user
#     category { "Weekly Weight Loss" }
#     start_date { Date.today }
    
#     user
#   end

#   factory :meal_plan_item do
#     meal_plan
#     scheduled_date { Date.today }
#     meal_slot { "breakfast" }
#     # Polymorphic association handling
#     association :plannable, factory: :recipe 
#   end

#   factory :recipe do
#     title { "Avocado Toast" }
#   end

#   factory :comment do
#     content { "Looking forward to this!" }
#     meal_plan
#     user
#   end
# end