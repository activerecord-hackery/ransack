FactoryBot.define do
  factory :article do
    association :person
    title { Faker::Lorem.sentence }
    body { Faker::Lorem.paragraph }
  end
end
