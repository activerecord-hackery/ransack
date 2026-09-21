module RansackHelper
  # The dialect of the database the suite is running against, for examples
  # whose expected SQL differs by backend.
  def self.dialect
    Ransack::ActiveRecord::Dialect.for(::ActiveRecord::Base)
  end

  def dialect
    RansackHelper.dialect
  end

  def quote_table_name(table)
    ::ActiveRecord::Base.lease_connection.quote_table_name(table)
  end

  def quote_column_name(column)
    ::ActiveRecord::Base.lease_connection.quote_column_name(column)
  end

  # Quotes a string the way the current adapter would render it as a SQL
  # literal, so specs can assert on generated SQL without hardcoding each
  # backend's escaping of backslashes.
  def quote_value(value)
    ::ActiveRecord::Base.lease_connection.quote(value)
  end
end
