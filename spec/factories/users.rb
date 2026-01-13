FactoryBot.define do
  factory :user do
    name     { Faker::Name.name }
    email    { Faker::Internet.unique.email }
    # Devise requires these for a valid user object
    password { "password123" }
    password_confirmation { "password123" }
    
    # Optional bio
    bio { Faker::Lorem.sentence }
    
    role { "standard" }

    trait :premium do
      role { "premium" }
    end
  end
end