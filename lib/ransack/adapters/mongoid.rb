require 'ransack/adapters/mongoid/base'
::Mongoid::Document.send :include, Ransack::Adapters::Mongoid::Base

require 'ransack/adapters/mongoid/attributes/attribute'
require 'ransack/adapters/mongoid/table'
require 'ransack/adapters/mongoid/inquiry_hash'

case ::Mongoid::VERSION
when /^3\.2\./
  require 'ransack/adapters/mongoid/3.2/context'
else
  require 'ransack/adapters/mongoid/context'
end

Ransack::SUPPORTS_ATTRIBUTE_ALIAS = false
