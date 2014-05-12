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

      self.predicates[name] = Predicate.new(opts)

      ['_any', '_all'].each do |suffix|
        self.predicates[name + suffix] = Predicate.new(
          opts.merge(
            :name => name + suffix,
            :arel_predicate => arel_predicate_with_suffix(opts[:arel_predicate], suffix),
            :compound => true
          )
        )
      end if compounds
    end

    # default search_key that, it can be overridden on sort_link level
    def search_key=(name)
      self.options[:search_key] = name
    end

    def arel_predicate_with_suffix arel_predicate, suffix
      case arel_predicate
      when Proc
        proc { |v| arel_predicate.call(v).to_s + suffix }
      else
        arel_predicate.to_s + suffix
      end
    end
  end
end
