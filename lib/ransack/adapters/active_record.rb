require 'ransack/adapters/active_record/base'
ActiveRecord::Base.extend Ransack::Adapters::ActiveRecord::Base

case ActiveRecord::VERSION::STRING
when /^3\.0\./
  require 'ransack/adapters/active_record/3.0/context'
when /^3\.1\./
  require 'ransack/adapters/active_record/3.1/context'
when /^3\.2\./
  require 'ransack/adapters/active_record/3.2/context'
else
  require 'ransack/adapters/active_record/context'
end
