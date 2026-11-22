module RansackHelper
  # The dialect of the database the suite is running against, for examples
  # whose expected SQL differs by backend.
  def self.dialect
    Ransack::ActiveRecord::Dialect.for(::ActiveRecord::Base)
  end

  def dialect
    RansackHelper.dialect
  end

  # The column and operator a case-insensitive predicate (i_cont, i_start,
  # i_end) renders for people.name: ILIKE on PostgreSQL, a bare LIKE on
  # MySQL, where the column's default `_ci` collation already ignores case,
  # and LIKE on LOWER(column) elsewhere.
  def self.i_like_name(negated: false)
    conn = ::ActiveRecord::Base.lease_connection
    field = "#{conn.quote_table_name('people')}.#{conn.quote_column_name('name')}"
    column = dialect.postgresql? || dialect.mysql? ? field : "LOWER(#{field})"
    operator = dialect.case_insensitive_like? ? 'ILIKE' : 'LIKE'
    "#{column} #{'NOT ' if negated}#{operator}"
  end

  def i_like_name(negated: false)
    Regexp.escape(RansackHelper.i_like_name(negated: negated))
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
