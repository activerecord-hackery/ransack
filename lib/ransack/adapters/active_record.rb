require 'ransack/adapters/active_record/base'
require 'ransack/adapters/active_record/join_dependency'
require 'ransack/adapters/active_record/join_association'
require 'ransack/adapters/active_record/context'

ActiveRecord::Base.extend Ransack::Adapters::ActiveRecord::Base
ActiveRecord::Associations::JoinDependency.send :include, Ransack::Adapters::ActiveRecord::JoinDependency