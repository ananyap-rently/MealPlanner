# spec/factories/payments.rb
FactoryBot.define do
  factory :payment do
    payment_status { 'pending' }
    association :shopping_list_item
    
    trait :pending do
      payment_status { 'pending' }
    end
    
    trait :completed do
      payment_status { 'completed' }
    end
  end
end