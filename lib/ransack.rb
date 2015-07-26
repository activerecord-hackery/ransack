require 'active_support/core_ext'

require 'ransack/configuration'

require 'ransack/adapters'
Ransack::Adapters.require_constants

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

Ransack::Adapters.require_adapter

ActionController::Base.helper Ransack::Helpers::FormHelper
