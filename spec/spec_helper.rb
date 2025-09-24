require 'rails'
require File.expand_path('../dummy/config/environment', __FILE__)

require 'ransack'
require 'factory_bot'
require 'faker'
require 'action_controller'
require 'ransack/helpers'
require 'pry'
require 'simplecov'
require 'byebug'

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
    
    # Run migrations for the dummy app
    ActiveRecord::Base.connection.migration_context.migrate
    
    # Seed test data using FactoryBot
    10.times do
      person = create(:person)
      create(:note, notable: person)
      3.times do
        article = create(:article, person: person)
        3.times do
          article.tags = [create(:tag), create(:tag), create(:tag)]
        end
        create(:note, notable: article)
        10.times do
          create(:comment, article: article, person: person)
        end
      end
    end

    create(:comment,
      body: 'First post!',
      article: create(:article, title: 'Hello, world!')
    )
    
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
