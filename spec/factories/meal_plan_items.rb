# spec/factories/meal_plan_items.rb
FactoryBot.define do
  factory :meal_plan_item do
    association :meal_plan
    scheduled_date { Faker::Date.forward(days: 30) }
    meal_slot { ['breakfast', 'lunch', 'dinner', 'snack'].sample }
    
    for_recipe

    trait :for_recipe do
      association :plannable, factory: :recipe
    end

    trait :for_item do
      association :plannable, factory: :item
    end
  end
end