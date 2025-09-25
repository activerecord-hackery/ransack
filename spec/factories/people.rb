FactoryBot.define do
  factory :person do
    name { Faker::Name.name }
    email { "test@example.com" }
    sequence(:salary) { |n| 30000 + (n * 1000) }
    only_sort { Faker::Lorem.words(number: 3).join(' ') }
    only_search { Faker::Lorem.words(number: 3).join(' ') }
    only_admin { Faker::Lorem.words(number: 3).join(' ') }
  end
end
