require 'ransack/constants'
require 'ransack/predicate'

module Ransack
  module Configuration

    mattr_accessor :predicates, :options
    self.predicates = {}
    self.options = {
        :search_key => :q
    }

    def configure
      yield self
    end

    def add_predicate(name, opts = {})
      name = name.to_s
      opts[:name] = name
      compounds = opts.delete(:compounds)
      compounds = true if compounds.nil?
      compounds = false if opts[:wants_array]
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

    # default search_key that, it can be overridden on sort_link level
    def search_key=(name)
      self.options[:search_key] = name
    end

  end
end
