FactoryBot.define do
  factory :note do
    note { Faker::Lorem.words(number: 7).join(' ') }
    
    trait :for_person do
      association :notable, factory: :person
    end
    
    trait :for_article do
      association :notable, factory: :article
    end
  end
end
