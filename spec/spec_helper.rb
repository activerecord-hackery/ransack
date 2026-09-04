require 'ransack'
require 'factory_bot'
require 'faker'
require 'action_controller'
require 'ransack/helpers'
require 'pry'
require 'simplecov'
require 'byebug'
require 'rspec'

SimpleCov.start
I18n.enforce_available_locales = false
Time.zone = 'Eastern Time (US & Canada)'
I18n.load_path += Dir[File.join(File.dirname(__FILE__), 'support', '*.yml')]

Dir[File.expand_path('../{helpers,support,factories}/*.rb', __FILE__)]
.each { |f| require f }

Faker::Config.random = Random.new(0)

RSpec.configure do |config|
  config.alias_it_should_behave_like_to :it_has_behavior, 'has behavior'
  
  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    message = "Running Ransack specs with #{
      ActiveRecord::Base.connection.adapter_name
      }, Active Record #{::ActiveRecord::VERSION::STRING}, Arel #{Arel::VERSION
      } and Ruby #{RUBY_VERSION}"
    line = '=' * message.length
    puts line, message, line
    Schema.create
    SubDB::Schema.create if defined?(SubDB)
  end

  config.include RansackHelper
  config.include PolyamorousHelper
end

RSpec::Matchers.define :be_like do |expected|
  match do |actual|
    actual.gsub(/^\s+|\s+$/, '').gsub(/\s+/, ' ').strip ==
      expected.gsub(/^\s+|\s+$/, '').gsub(/\s+/, ' ').strip
  end
end

RSpec::Matchers.define :have_attribute_method do |expected|
  match do |actual|
    actual.attribute_method?(expected)
  end
end
