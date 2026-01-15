# spec/factories/comments.rb
# FactoryBot.define do
#   factory :comment do
#     content { Faker::Lorem.paragraph }
#     association :user
    
#     trait :for_recipe do
#       association :commentable, factory: :recipe
#     end
#   end
# end
# spec/factories/comments.rb
FactoryBot.define do
  factory :comment do
    content { Faker::Lorem.sentence }
    association :user
    commentable { nil }
    commentable_type { nil }
    
    trait :for_recipe do
      association :commentable, factory: :recipe
      commentable_type { 'Recipe' }
    end
  end
end