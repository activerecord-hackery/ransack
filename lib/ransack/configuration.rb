require 'ransack/constants'
require 'ransack/predicate'

module Ransack
  module Configuration

    mattr_accessor :predicates, :options
    self.predicates = {}
    self.options = {
      :search_key => :q,
      :ignore_unknown_conditions => true
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

      self.predicates[name] = Predicate.new(opts)

      ['_any', '_all'].each do |suffix|
        compound_name = name + suffix
        self.predicates[compound_name] = Predicate.new(
          opts.merge(
            :name => compound_name,
            :arel_predicate => arel_predicate_with_suffix(
              opts[:arel_predicate], suffix
              ),
            :compound => true
          )
        )
      end if compounds
    end

    # default search_key that, it can be overridden on sort_link level
    def search_key=(name)
      self.options[:search_key] = name
    end

    # raise an error if an unknown predicate, condition or attribute is passed
    # into a search
    def ignore_unknown_conditions=(boolean)
      self.options[:ignore_unknown_conditions] = boolean
    end

    def arel_predicate_with_suffix(arel_predicate, suffix)
      if arel_predicate === Proc
        proc { |v| "#{arel_predicate.call(v)}#{suffix}" }
      else
        "#{arel_predicate}#{suffix}"
      end
    end

  end
end
