require 'ransack/adapters/active_record/base'
ActiveRecord::Base.extend Ransack::Adapters::ActiveRecord::Base

case ActiveRecord::VERSION::STRING
when /^3\.0\./
  require 'ransack/adapters/active_record/3.0/join_dependency'
  require 'ransack/adapters/active_record/3.0/join_association'
  require 'ransack/adapters/active_record/3.0/context'

  ActiveRecord::Associations::ClassMethods::JoinDependency.send :include, Ransack::Adapters::ActiveRecord::JoinDependency
else
  require 'ransack/adapters/active_record/join_dependency'
  require 'ransack/adapters/active_record/join_association'
  require 'ransack/adapters/active_record/context'

  ActiveRecord::Associations::JoinDependency.send :include, Ransack::Adapters::ActiveRecord::JoinDependency
end