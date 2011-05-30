require 'ransack/configuration'

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
require 'ransack/search'
require 'ransack/ransacker'
require 'ransack/adapters/active_record'
require 'ransack/helpers'
require 'action_controller'

ActionController::Base.helper Ransack::Helpers::FormHelper