require 'ransack/adapters/mongoid/base'
Mongoid::Document.extend Ransack::Adapters::Mongoid::Base

case Mongoid::VERSION::STRING
when /^3\.2\./
  require 'ransack/adapters/mongoid/3.2/context'
else
  require 'ransack/adapters/mongoid/context'
end
