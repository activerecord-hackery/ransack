module Ransack
  module Translate

    def self.i18n_key(klass)
      if ActiveRecord::VERSION::MAJOR == 3 && ActiveRecord::VERSION::MINOR == 0
        klass.model_name.i18n_key.to_s.tr('.'.freeze, '/'.freeze)
      else
        klass.model_name.i18n_key.to_s.freeze
      end
    end
  end
end
