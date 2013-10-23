require 'active_record'
require 'ransack/adapters/active_record/base'
ActiveRecord::Base.extend Ransack::Adapters::ActiveRecord::Base

module Ransack
  module Adapters
    module ActiveRecord
      case ::ActiveRecord::VERSION::STRING
      when /^3\.0\./
        autoload :Context, 'ransack/adapters/active_record/3.0/context'
      when /^3\.1\./
        autoload :Context, 'ransack/adapters/active_record/3.1/context'
      when /^3\.2\./
        autoload :Context, 'ransack/adapters/active_record/3.2/context'
      else
        autoload :Context, 'ransack/adapters/active_record/context'
      end
    end
  end
end
