module Ransack
  # @see https://github.com/activerecord-hackery/ransack/issues/429
  # 
  # Handles DISTINCT queries with ORDER BY clauses to fix PostgreSQL compatibility issues.
  # When using DISTINCT, all columns in ORDER BY must also be present in the SELECT clause.
  class DistinctSortsProcessor
    # Regex pattern to match ORDER BY clauses (ASC/DESC with optional NULLS FIRST/LAST)
    ORDER_BY_PATTERN = /\s+(asc|desc)(\s+nulls\s+(first|last))?$/i.freeze

    attr_reader :search, :query, :sorts

    # @param search [Ransack::Search] The Ransack search object
    # @param query [ActiveRecord::Relation] The ActiveRecord relation
    # @param sorts [Array] Array of sort objects
    def initialize(search, query, sorts)
      @search = search
      @query = query
      @sorts = sorts
    end

    # @param query [ActiveRecord::Relation] The query to check
    # @param sorts [Array] Array of sort objects
    # @return [Boolean] true if processing is needed
    def self.should_process?(query, sorts)
      query.distinct_value == true && sorts.any?
    end

    # Processes the distinct sorts by modifying the query to include necessary SELECT clauses
    # and updating the ORDER BY clause to use aliased columns.
    def process!
      return if sorts.empty?

      processed_sorts = process_sorts
      return if processed_sorts.empty?

      add_necessary_selects(processed_sorts)
      update_order_values(processed_sorts)
    end

    private

    # Processes all sorts and returns only those that need processing
    def process_sorts
      sorts.flat_map { |sort| process_sort(sort) }
    end

    def process_sort(sort)
      if sort.is_a?(String)
        sql_sorts = split_sql_expression(sort)
        sql_sorts.map { |sql_sort| process_single_sort(sql_sort) }
      else
        process_single_sort(sort)
      end
    end

    # Processes a single sort and returns processing info if needed
    def process_single_sort(sort)
      existing_alias = find_existing_select_alias(sort)

      if existing_alias
        { original_sort: sort }
      else
        alias_name = generate_alias_name
        select_value = build_select_value(sort, alias_name)

        return { original_sort: sort } if select_value.nil?

        {
          original_sort: sort,
          alias_name: alias_name,
          select_value: select_value
        }
      end
    end

    # Finds if a sort expression already exists in the SELECT clause
    def find_existing_select_alias(sort)
      sort_expression = extract_sort_expression(sort)
      return nil unless sort_expression

      query.select_values.each do |select_value|
        select_str = select_value.to_s.strip

        return extract_alias_from_select(select_str) if matches_select_expression?(select_str, sort_expression)
      end

      nil
    end

    def matches_select_expression?(select_str, sort_expression)
      select_str.include?(sort_expression) ||
        !!select_str.match(/#{Regexp.escape(sort_expression)}\s+AS\s+(\w+)/i)
    end

    # Extracts the alias from a SELECT expression, handling subqueries and regular columns
    # @example
    #   extract_alias_from_select("SUM(hours) AS total_hours")           # => "total_hours"
    #   extract_alias_from_select("(SELECT COUNT(*) FROM users) AS cnt") # => "cnt"
    #   extract_alias_from_select("users.name AS username")              # => "username"
    #   extract_alias_from_select("COUNT(*)")                            # => nil
    #
    def extract_alias_from_select(select_str)
      select_str = select_str.strip
      # Attempt to find the last occurrence of "AS alias"
      match = select_str.match(/AS\s+(\w+)\s*\z/i)
      match ? match[1] : nil
    end

    def extract_sort(sort)
      case sort
      when Arel::Nodes::Ordering
        case sort.expr
        when Arel::Attributes::Attribute
          sort.expr.name.to_s
        when Arel::Nodes::SqlLiteral
          sort.expr.to_s
        else
          sort.expr.to_sql
        end
      when String
        sort
      end
    end

    # Extracts the pure expression from a sort (without ORDER BY clauses)
    def extract_sort_expression(sort)
      sort_expression = extract_sort(sort)
      remove_order_by_clauses(sort_expression) if sort_expression
    end

    # Removes ORDER BY clauses from a sort expression
    def remove_order_by_clauses(sort_expression)
      sort_expression.sub(ORDER_BY_PATTERN, '').strip
    end

    # Generates a unique alias name
    def generate_alias_name
      "alias_#{SecureRandom.hex(8)}"
    end

    def build_select_value(sort, alias_name)
      if sort.is_a?(Arel::Nodes::Ordering) && sort.expr.is_a?(Arel::Attributes::Attribute)
        column_name = sort.expr.name.to_s
        relation_name = sort.expr.relation.name
        return nil if should_skip_column?(column_name, relation_name)
      end

      expr = extract_sort_expression(sort)
      Arel.sql("#{expr} AS #{alias_name}") unless expr.nil?
    end

    def split_sql_expression(expr)
      Utilities::SqlExpressionParser.split_sql_expression(expr)
    end

    def should_skip_column?(column_name, relation_name)
      return false unless query.select_values.empty?

      column_names = search.klass.column_names.map(&:to_s)
      column_names.include?(column_name) && relation_name == search.klass.table_name
    end

    def add_necessary_selects(processed_sorts)
      query.select_values = [Arel.sql("#{query.table.name}.*")] if query.select_values.empty?

      new_selects = processed_sorts.filter_map { |sort_info| sort_info[:select_value] }
      query.select_values += new_selects if new_selects.any?
    end

    def update_order_values(processed_sorts)
      query.order_values = processed_sorts.map { |sort_info| build_order_value(sort_info) }
    end

    def build_order_value(sort_info)
      original_sort = sort_info[:original_sort]
      alias_name = sort_info[:alias_name]

      return original_sort unless alias_name

      direction = extract_sort_direction(original_sort) || ''

      Arel.sql("#{alias_name} #{direction}")
    end

    def extract_sort_direction(sort)
      case sort
      when Arel::Nodes::Ordering
        sort.direction.to_s.upcase
      when String
        extract_order_by_clauses(sort)
      end
    end

    # Extracts the direction and nulls handling from a sort expression
    def extract_order_by_clauses(sort_expression)
      match = sort_expression.match(ORDER_BY_PATTERN)
      return nil unless match

      direction = match[1].upcase
      nulls = match[2]&.upcase&.strip
      [direction, nulls].compact.join(' ')
    end
  end
end
