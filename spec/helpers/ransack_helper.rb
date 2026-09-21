module RansackHelper
  def quote_table_name(table)
    ActiveRecord::Base.connection.quote_table_name(table)
  end

  def quote_column_name(column)
    ActiveRecord::Base.connection.quote_column_name(column)
  end

  # Quotes a string the way the current adapter would render it as a SQL
  # literal, so specs can assert on generated SQL without hardcoding each
  # backend's escaping of backslashes.
  def quote_value(value)
    ActiveRecord::Base.connection.quote(value)
  end
end
