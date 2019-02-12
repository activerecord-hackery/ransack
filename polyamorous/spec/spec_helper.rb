require 'machinist/active_record'
require 'sham'
require 'faker'
require 'polyamorous'

Time.zone = 'Eastern Time (US & Canada)'

Dir[File.expand_path('../{helpers,support,blueprints}/**/*.rb', __FILE__)]
.each do |f|
  require f
end

Sham.define do
  name     { Faker::Name.name }
  title    { Faker::Lorem.sentence }
  body     { Faker::Lorem.paragraph }
  salary   { |index| 30000 + (index * 1000) }
  tag_name { Faker::Lorem.words(3).join(' ') }
  note     { Faker::Lorem.words(7).join(' ') }
end

RSpec.configure do |config|
  config.before(:suite) do
    message = "Running Polyamorous specs with #{
      ActiveRecord::Base.connection.adapter_name
      }, Active Record #{::ActiveRecord::VERSION::STRING}, Arel #{Arel::VERSION
      } and Ruby #{RUBY_VERSION}"
    line = '=' * message.length
    puts line, message, line
    Schema.create
  end
  config.before(:all)   { Sham.reset(:before_all) }
  config.before(:each)  { Sham.reset(:before_each) }

  config.include PolyamorousHelper
end

RSpec::Matchers.define :be_like do |expected|
  match do |actual|
    actual.gsub(/^\s+|\s+$/, '').gsub(/\s+/, ' ').strip ==
      expected.gsub(/^\s+|\s+$/, '').gsub(/\s+/, ' ').strip
  end
end
