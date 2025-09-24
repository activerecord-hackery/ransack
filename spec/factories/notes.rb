FactoryBot.define do
  factory :note do
    note { Faker::Lorem.words(number: 7).join(' ') }
    notable_type { "Article" }
    notable_id { |n| n }
  end
end