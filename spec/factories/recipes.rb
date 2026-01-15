# spec/factories/recipes.rb
FactoryBot.define do
  factory :recipe do
    title { Faker::Food.dish }
    instructions { Faker::Lorem.paragraph(sentence_count: 5) }
    prep_time { rand(10..120) }
    servings { rand(2..8) }
    association :user

     # Ensure we always have valid string values to avoid TypeErrors
    after(:build) do |recipe|
      recipe.title ||= "Default Recipe Title"
      recipe.instructions ||= "Default recipe instructions"
      recipe.prep_time ||= 30
      recipe.servings ||= 4
    end

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