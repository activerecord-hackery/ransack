module Ransack
  # @see https://github.com/activerecord-hackery/ransack/issues/429
  # 
  # Handles DISTINCT queries with ORDER BY clauses to fix PostgreSQL compatibility issues.
  # When using DISTINCT, all columns in ORDER BY must also be present in the SELECT clause.
  class DistinctSortsProcessor
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
      select_sorts = build_select_sorts
      
      add_default_select_if_needed
      add_sort_selects(select_sorts)
      update_order_values(select_sorts)
    end

    private

    def build_select_sorts
      sorts.map { |sort| build_select_sort(sort) }.compact
    end

    def build_select_sort(sort)
      alias_name = generate_alias_name
      select_value = extract_select_value(sort, alias_name)
      
      return nil unless select_value

      {
        sort: sort,
        select: select_value,
        alias_name: alias_name
      }
    end

    def generate_alias_name
      "alias_#{SecureRandom.hex(10)}"
    end

    def extract_select_value(sort, alias_name)
      case sort
      when Arel::Nodes::Ordering
        extract_ordering_select_value(sort, alias_name)
      when String
        extract_string_select_value(sort, alias_name)
      else
        nil
      end
    end

    def extract_ordering_select_value(sort, alias_name)
      return nil unless sort.expr.is_a?(Arel::Attributes::Attribute)

      column_name = sort.expr.name.to_s
      relation_name = sort.expr.relation.name
      
      # Skip if the column is already selected to avoid ambiguous columns
      return nil if should_skip_column?(column_name, relation_name)

      sort.expr.as(alias_name)
    end

    def extract_string_select_value(sort, alias_name)
      # Remove ORDER BY clauses and add alias
      expr = sort.sub(/\s+(asc|desc)(\s+nulls\s+(first|last))?/i, '')
      Arel.sql("#{expr} AS #{alias_name}")
    end

    def should_skip_column?(column_name, relation_name)
      select_all = search.instance_variable_get(:@context).evaluate(search).select_values.empty?
      column_names = search.klass.column_names.map(&:to_s)
      
      select_all && column_names.include?(column_name) && relation_name == search.klass.table_name
    end

    def add_default_select_if_needed
      if query.select_values.empty?
        query.select_values += [Arel.sql("#{query.table.name}.*")]
      end
    end

    def add_sort_selects(select_sorts)
      query.select_values += select_sorts.pluck(:select)
    end

    def update_order_values(select_sorts)
      query.order_values = select_sorts.map do |sort_info|
        build_new_order_value(sort_info)
      end
    end

    def build_new_order_value(sort_info)
      original_sort = sort_info[:sort]
      direction = extract_sort_direction(original_sort) || ''
      
      Arel.sql("#{sort_info[:alias_name]} #{direction}")
    end

    def extract_sort_direction(sort)
      case sort
      when Arel::Nodes::Ordering
        sort.direction.to_s.upcase
      when String
        match = sort.match(/(asc|desc)(\s+nulls\s+(first|last))?/i)
        if match
          direction = match[1].upcase
          nulls = match[2]&.upcase&.strip
          [direction, nulls].compact.join(' ')
        end
      else
        nil
      end
    end
  end
end
