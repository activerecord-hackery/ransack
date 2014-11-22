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

      Constants::SUFFIXES.each do |suffix|
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

    # The default `search_key` name is `:q`. The default key may be overridden
    # in an initializer file like `config/initializers/ransack.rb` as follows:
    #
    # Ransack.configure do |config|
    #   # Name the search_key `:query` instead of the default `:q`
    #   config.search_key = :query
    # end
    #
    # Sometimes there are situations when the default search parameter name
    # cannot be used, for instance if there were two searches on one page.
    # Another name can be set using the `search_key` option with Ransack
    # `ransack`, `search` and `@search_form_for` methods in controllers & views.
    #
    # In the controller:
    # @search = Log.ransack(params[:log_search], search_key: :log_search)
    #
    # In the view:
    # <%= f.search_form_for @search, as: :log_search %>
    #
    def search_key=(name)
      self.options[:search_key] = name
    end

    # Raise an error if an unknown predicate, condition or attribute is passed
    # into a search.
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
