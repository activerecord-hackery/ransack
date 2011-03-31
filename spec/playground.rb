$VERBOSE = false
require 'bundler'
Bundler.setup
require 'machinist/active_record'
require 'sham'
require 'faker'

Dir[File.expand_path('../../spec/{helpers,support,blueprints}/*.rb', __FILE__)].each do |f|
  require f
end

Sham.define do
  name     { Faker::Name.name }
  title    { Faker::Lorem.sentence }
  body     { Faker::Lorem.paragraph }
  salary   {|index| 30000 + (index * 1000)}
  tag_name { Faker::Lorem.words(3).join(' ') }
  note     { Faker::Lorem.words(7).join(' ') }
end

Schema.create

require 'ransack'

Article.joins{person.comments}.where{person.comments.body =~ '%hello%'}.to_sql
# => "SELECT \"articles\".* FROM \"articles\" INNER JOIN \"people\" ON \"people\".\"id\" = \"articles\".\"person_id\" INNER JOIN \"comments\" ON \"comments\".\"person_id\" = \"people\".\"id\" WHERE \"comments\".\"body\" LIKE '%hello%'"

Person.where{(id + 1) == 2}.first
# => #<Person id: 1, parent_id: nil, name: "Aric Smith", salary: 31000>

Person.where{(salary - 40000) < 0}.to_sql
# => "SELECT \"people\".* FROM \"people\"  WHERE \"people\".\"salary\" - 40000 < 0"

p = Person.select{[id, name, salary, (salary + 1000).as('salary_after_increase')]}.first
# => #<Person id: 1, name: "Aric Smith", salary: 31000>

p.salary_after_increase # =>