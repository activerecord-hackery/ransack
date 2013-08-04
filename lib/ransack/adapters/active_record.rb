require 'active_record'
require 'ransack/adapters/active_record/base'
ActiveRecord::Base.extend Ransack::Adapters::ActiveRecord::Base

require 'ransack/adapters/active_record/context'
