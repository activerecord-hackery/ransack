require 'ransack/constants'
require 'ransack/predicate'

ASC                 = 'asc'.freeze
DESC                = 'desc'.freeze
ASC_ARROW           = '&#9650;'.freeze
DESC_ARROW          = '&#9660;'.freeze
OR                  = 'or'.freeze
AND                 = 'and'.freeze
SORT                = 'sort'.freeze
SORT_LINK           = 'sort_link'.freeze
SEARCH              = 'search'.freeze
DEFAULT_SEARCH_KEY  = 'q'.freeze
ATTRIBUTE           = 'attribute'.freeze
DISTINCT            = 'DISTINCT '.freeze
COMBINATOR          = 'combinator'.freeze
SPACE               = ' '.freeze
COMMA_SPACE         = ', '.freeze
UNDERSCORE          = '_'.freeze
NON_BREAKING_SPACE  = '&nbsp;'.freeze
EMPTY_STRING        = ''.freeze

ASC_DESC            = %w(asc desc).freeze
AND_OR              = %w(and or).freeze
IN_NOT_IN           = %w(in not_in).freeze
SUFFIXES            = %w(_any _all).freeze

STRING_JOIN         = 'string_join'.freeze
ASSOCIATION_JOIN    = 'association_join'.freeze
STASHED_JOIN        = 'stashed_join'.freeze
JOIN_NODE           = 'join_node'.freeze

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

      SUFFIXES.each do |suffix|
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
