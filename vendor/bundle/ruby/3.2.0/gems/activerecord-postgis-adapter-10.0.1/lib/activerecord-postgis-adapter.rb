# frozen_string_literal: true

require "active_record"
require "active_record/connection_adapters"
require "rgeo/active_record"
ActiveRecord::ConnectionAdapters.register("postgis", "ActiveRecord::ConnectionAdapters::PostGISAdapter", "active_record/connection_adapters/postgis_adapter")
ActiveRecord::Tasks::DatabaseTasks.register_task(/postgis/, "ActiveRecord::Tasks::PostgreSQLDatabaseTasks")
