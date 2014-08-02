module RansackHelper
  def quote_table_name(table)
    # ActiveRecord::Base.connection.quote_table_name(table)
    table
  end

  def quote_column_name(column)
    # ActiveRecord::Base.connection.quote_column_name(column)
    column
  end
end