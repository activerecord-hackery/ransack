module Ransack
  module Naming

    def self.included(base)
      base.extend ClassMethods
    end

    def persisted?
      false
    end

    def to_key
      nil
    end

    def to_param
      nil
    end

    def to_model
      self
    end
  end

  class Name < String
    attr_reader :singular, :plural, :element, :collection, :partial_path,
                :human, :param_key, :route_key, :i18n_key
    alias_method :cache_key, :collection

    def initialize
      super("Search")
      @singular = "search".freeze
      @plural = "searches".freeze
      @element = "search".freeze
      @human = "Search".freeze
      @collection = "ransack/searches".freeze
      @partial_path = "#{@collection}/#{@element}".freeze
      @param_key = "q".freeze
      @route_key = "searches".freeze
      @i18n_key = :ransack
    end
  end

  module ClassMethods
    def model_name
      @_model_name ||= Name.new
    end

    def i18n_scope
      :ransack
    end
  end

end