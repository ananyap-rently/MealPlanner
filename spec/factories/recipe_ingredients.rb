# spec/factories/recipe_ingredients.rb
FactoryBot.define do
  factory :recipe_ingredient do
    association :recipe
    association :ingredient
   quantity { rand(1..5).to_s }
   #quantity { 2.0 }
    unit { ['cups', 'tbsp', 'tsp', 'oz', 'grams', 'ml'].sample }
  end
end