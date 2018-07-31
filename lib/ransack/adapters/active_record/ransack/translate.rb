module Ransack
  module Translate

    def self.i18n_key(klass)
      klass.model_name.i18n_key.to_s.freeze
    end
  end
end
