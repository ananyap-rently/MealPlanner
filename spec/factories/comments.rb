# spec/factories/comments.rb
FactoryBot.define do
  factory :comment do
    content { Faker::Lorem.paragraph }
    association :user
    
    trait :for_recipe do
      association :commentable, factory: :recipe
    end
  end
end