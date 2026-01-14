# spec/factories/recipes.rb
FactoryBot.define do
  factory :recipe do
    title { Faker::Food.dish }
    prep_time { rand(10..120) }
    servings { rand(2..8) }
    association :user

    trait :with_ingredients do
      after(:create) do |recipe|
        create_list(:recipe_ingredient, 3, recipe: recipe)
      end
    end

    trait :with_tags do
      after(:create) do |recipe|
        create_list(:tag, 2).each do |tag|
          recipe.tags << tag
        end
      end
    end

    trait :with_comments do
      after(:create) do |recipe|
        create_list(:comment, 2, commentable: recipe)
      end
    end

    trait :complete do
      with_ingredients
      with_tags
      with_comments
    end
  end
end