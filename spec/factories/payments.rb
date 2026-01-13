FactoryBot.define do
  factory :payment do
    # This automatically creates a ShoppingListItem and assigns its ID
    #association :shopping_list_item 
    
    payment_status { "pending" } # Default status

    # Traits for different payment states
    trait :completed do
      payment_status { "completed" }
    end

    trait :failed do
      payment_status { "failed" }
    end
  end
end