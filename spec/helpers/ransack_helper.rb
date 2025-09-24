module RansackHelper
  def quote_table_name(table)
    ActiveRecord::Base.lease_connection.quote_table_name(table)
  end

  def quote_column_name(column)
    ActiveRecord::Base.lease_connection.quote_column_name(column)
  end
end
