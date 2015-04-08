require 'active_support/core_ext'

require 'ransack/configuration'

if defined?(::Mongoid)
  require 'ransack/adapters/mongoid/ransack/constants'
else
  require 'ransack/adapters/active_record/ransack/constants'
end

module Ransack
  extend Configuration
  class UntraversableAssociationError < StandardError; end;
end

Ransack.configure do |config|
  Ransack::Constants::AREL_PREDICATES.each do |name|
    config.add_predicate name, :arel_predicate => name
  end
  Ransack::Constants::DERIVED_PREDICATES.each do |args|
    config.add_predicate *args
  end
end

require 'ransack/search'
require 'ransack/ransacker'
require 'ransack/helpers'
require 'action_controller'

require 'ransack/translate'

if defined?(::ActiveRecord::Base)
  require 'ransack/adapters/active_record/ransack/translate'
  require 'ransack/adapters/active_record'
end

if defined?(::Mongoid)
  require 'ransack/adapters/mongoid/ransack/translate'
  require 'ransack/adapters/mongoid'
end

ActionController::Base.helper Ransack::Helpers::FormHelper
