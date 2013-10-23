module Ransack
  autoload :Configuration,  'ransack/configuration'
  autoload :Constants,      'ransack/constants'
  autoload :Context,        'ransack/context'
  autoload :Helpers,        'ransack/helpers'
  autoload :Naming,         'ransack/naming'
  autoload :Nodes,          'ransack/nodes'
  autoload :Predicate,      'ransack/predicate'
  autoload :Ransacker,      'ransack/ransacker'
  autoload :Search,         'ransack/search'
  autoload :Visitor,        'ransack/visitor'

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
require 'ransack/adapters/active_record'
require 'action_controller'

ActionController::Base.helper Ransack::Helpers::FormHelper
