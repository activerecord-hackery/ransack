Bundler.setup
require 'factory_bot'
require 'faker'
require 'ransack'

Dir[File.expand_path('../../spec/{helpers,support,factories}/*.rb', __FILE__)]
.each do |f|
  require f
end

Faker::Config.random = Random.new(0)

Schema.create
