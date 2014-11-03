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

require 'ransack/translate'
require 'ransack/adapters/active_record/ransack/translate' if defined?(::ActiveRecord::Base)
require 'ransack/adapters/mongoid/ransack/translate' if defined?(::Mongoid)
require 'ransack/search'
require 'ransack/ransacker'
require 'ransack/adapters/active_record' if defined?(::ActiveRecord::Base)
require 'ransack/adapters/mongoid' if defined?(::Mongoid)
require 'ransack/helpers'
require 'action_controller'

ActionController::Base.helper Ransack::Helpers::FormHelper
