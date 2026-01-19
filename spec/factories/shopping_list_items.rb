# # spec/factories/shopping_list_items.rb
# FactoryBot.define do
#   factory :shopping_list_item do
#     quantity { rand(1..10) }
#     is_purchased { false }
#     association :user
    
#     # Polymorphic association - defaults to ingredient
#     association :purchasable, factory: :ingredient
    
#     trait :for_ingredient do
#       association :purchasable, factory: :ingredient
#     end
    
#     trait :for_recipe do
#       association :purchasable, factory: :recipe
#     end
#   end
# end
FactoryBot.define do
  factory :shopping_list_item do
    association :user
    association :meal_plan # Optional by default, but useful to have
    quantity { "2 units" }
    is_purchased { false }

    # Default to Ingredient as purchasable
    for_ingredient

    trait :for_ingredient do
      association :purchasable, factory: :ingredient
    end

    trait :for_item do
      association :purchasable, factory: :item
    end

    trait :purchased do
      is_purchased { true }
    end
  end
end