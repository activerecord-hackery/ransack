require 'active_support/dependencies/autoload'
require 'active_support/deprecation'
require 'active_support/version'

if ::ActiveSupport.version >= ::Gem::Version.new("7.1")
  require 'active_support/deprecator'
end

require 'active_support/core_ext'
require 'ransack/configuration'
require 'polyamorous/polyamorous'

module Ransack
  extend Configuration
  class UntraversableAssociationError < StandardError; end
end

Ransack.configure do |config|
  Ransack::Constants::AREL_PREDICATES.each do |name|
    config.add_predicate name, arel_predicate: name
  end
  Ransack::Constants::DERIVED_PREDICATES.each do |args|
    config.add_predicate(*args)
  end
end

require 'ransack/search'
require 'ransack/ransacker'
require 'ransack/translate'
require 'ransack/active_record'
require 'ransack/context'
require 'ransack/version'

ActiveSupport.on_load(:action_controller) do
  require 'ransack/helpers'
  ActionController::Base.helper Ransack::Helpers::FormHelper
end
