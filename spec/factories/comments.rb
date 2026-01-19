# # spec/factories/comments.rb

# FactoryBot.define do
#   factory :comment do
#     content { Faker::Lorem.sentence }
#     association :user
#     commentable { nil }
#     commentable_type { nil }
    
#     trait :for_recipe do
#       association :commentable, factory: :recipe
#       commentable_type { 'Recipe' }
#     end
#     trait :for_ingredient do
#       association :commentable, factory: :ingredient
#     end
#   end
# end
FactoryBot.define do
  factory :comment do
    content { "This is a comment." }
    association :user
    #association :commentable, factory: :meal_plan
    # Defaulting to recipe
    association :commentable, factory: :recipe

    trait :for_recipe do
      association :commentable, factory: :recipe
    end

    trait :for_ingredient do
      association :commentable, factory: :ingredient
    end
    trait :for_meal_plan do
      association :commentable, factory: :meal_plan
    end
  end
end