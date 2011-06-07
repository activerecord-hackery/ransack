require 'ransack/constants'
require 'ransack/predicate'

module Ransack
  module Configuration

    mattr_accessor :predicates
    self.predicates = {}

    def configure
      yield self
    end

    def add_predicate(name, opts = {})
      name = name.to_s
      opts[:name] = name
      compounds = opts.delete(:compounds)
      compounds = true if compounds.nil?
      opts[:arel_predicate] = opts[:arel_predicate].to_s

      self.predicates[name] = Predicate.new(opts)

      ['_any', '_all'].each do |suffix|
        self.predicates[name + suffix] = Predicate.new(
          opts.merge(
            :name => name + suffix,
            :arel_predicate => opts[:arel_predicate] + suffix,
            :compound => true
          )
        )
      end if compounds
    end

  end
end