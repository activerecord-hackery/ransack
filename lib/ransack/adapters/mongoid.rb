require 'ransack/adapters/mongoid/base'
Mongoid::Document.send :include, Ransack::Adapters::Mongoid::Base

require 'ransack/adapters/mongoid/attributes/attribute'
require 'ransack/adapters/mongoid/table'

case Mongoid::VERSION
when /^3\.2\./
  require 'ransack/adapters/mongoid/3.2/context'
else
  require 'ransack/adapters/mongoid/context'
end
