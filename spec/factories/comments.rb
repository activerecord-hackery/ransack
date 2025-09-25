FactoryBot.define do
  factory :comment do
    association :article
    association :person
    body { Faker::Lorem.paragraph }
  end
end
