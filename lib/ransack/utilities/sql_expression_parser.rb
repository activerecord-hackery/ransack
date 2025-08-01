module Ransack
  module Utilities
    # Utility class for parsing SQL expressions, particularly for splitting
    # complex SQL expressions while respecting quotes, brackets, and parentheses.
    class SqlExpressionParser
      # Quote characters that can be used in SQL expressions
      QUOTE_CHARS = ["'", '"', '`'].freeze

      # Splits a SQL expression by commas while respecting quoted strings,
      # brackets, and parentheses to avoid splitting within sub-expressions.
      #
      # @param expr [String] The SQL expression to split
      # @return [Array<String>] Array of individual SQL expression parts
      #
      # @example
      #   split_sql_expression("COUNT(x) desc, SUM(y)) asc")
      #   # => ["COUNT(x) desc", "SUM(y))) asc"]
      #
      #   split_sql_expression("COUNT(x), SUM(y)")
      #   # => ["COUNT(x)", "SUM(y)"]
      #
      #   split_sql_expression("COUNT(x), SUM(y), AVG(z)")
      #   # => ["COUNT(x)", "SUM(y)", "AVG(z)"]
      def self.split_sql_expression(expr)
        parts = []
        buffer = ''
        stack = []
        quote = nil
        i = 0
      
        bracket_pairs = { '(' => ')', '[' => ']', '{' => '}' }
        closing_brackets = bracket_pairs.values
      
        while i < expr.length
          char = expr[i]
          next_char = expr[i + 1]
      
          if quote
            if char == '\\' && next_char == quote
              # Handle MySQL-style escaped quote with backslash (e.g., \' or \")
              buffer << char << next_char
              i += 1
            elsif char == quote
              if quote != '`' && next_char == quote
                # Handle doubled quote for SQL string (e.g., '' or "")
                buffer << char << next_char
                i += 1
              else
                quote = nil
                buffer << char
              end
            else
              buffer << char
            end
          elsif QUOTE_CHARS.include?(char)
            quote = char
            buffer << char
          elsif bracket_pairs.key?(char)
            stack << bracket_pairs[char]
            buffer << char
          elsif closing_brackets.include?(char)
            stack.pop if stack.last == char
            buffer << char
          elsif char == ',' && stack.empty?
            parts << buffer.strip unless buffer.strip.empty?
            buffer = ''
          else
            buffer << char
          end
      
          i += 1
        end
      
        parts << buffer.strip unless buffer.strip.empty?
        parts
      end
    end
  end
end
