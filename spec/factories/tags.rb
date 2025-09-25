FactoryBot.define do
  factory :tag do
    name { Faker::Lorem.words(number: 3).join(' ') }
  end
end
