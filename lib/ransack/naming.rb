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
      super(Ransack::Constants::CAP_SEARCH)
      @singular     = Ransack::Constants::SEARCH
      @plural       = Ransack::Constants::SEARCHES
      @element      = Ransack::Constants::SEARCH
      @human        = Ransack::Constants::CAP_SEARCH
      @collection   = Ransack::Constants::RANSACK_SLASH_SEARCHES
      @partial_path = Ransack::Constants::RANSACK_SLASH_SEARCHES_SLASH_SEARCH
      @param_key    = Ransack::Constants::Q
      @route_key    = Ransack::Constants::SEARCHES
      @i18n_key     = :ransack
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
