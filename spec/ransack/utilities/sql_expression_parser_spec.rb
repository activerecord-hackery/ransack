require 'spec_helper'

module Ransack
  module Utilities
    describe SqlExpressionParser do
      describe '.split_sql_expression' do
        context 'with basic SQL expressions' do
          it 'splits simple comma-separated expressions' do
            expr = "COUNT(x), SUM(y)"
            result = SqlExpressionParser.split_sql_expression(expr)
            expect(result).to eq(["COUNT(x)", "SUM(y)"])
          end

          it 'splits multiple comma-separated expressions' do
            expr = "COUNT(x), SUM(y), AVG(z)"
            result = SqlExpressionParser.split_sql_expression(expr)
            expect(result).to eq(["COUNT(x)", "SUM(y)", "AVG(z)"])
          end

          it 'handles single expression without commas' do
            expr = "COUNT(x)"
            result = SqlExpressionParser.split_sql_expression(expr)
            expect(result).to eq(["COUNT(x)"])
          end

          it 'handles empty string' do
            expr = ""
            result = SqlExpressionParser.split_sql_expression(expr)
            expect(result).to eq([])
          end

          it 'handles whitespace-only string' do
            expr = "   "
            result = SqlExpressionParser.split_sql_expression(expr)
            expect(result).to eq([])
          end

          it 'trims whitespace from parts' do
            expr = "  COUNT(x)  ,  SUM(y)  "
            result = SqlExpressionParser.split_sql_expression(expr)
            expect(result).to eq(["COUNT(x)", "SUM(y)"])
          end
        end

        context 'with ORDER BY clauses' do
          it 'handles expressions with ASC/DESC' do
            expr = "COUNT(x) desc, SUM(y) asc"
            result = SqlExpressionParser.split_sql_expression(expr)
            expect(result).to eq(["COUNT(x) desc", "SUM(y) asc"])
          end

          it 'handles expressions with extra parentheses' do
            expr = "COUNT(x) desc, SUM(y)) asc"
            result = SqlExpressionParser.split_sql_expression(expr)
            expect(result).to eq(["COUNT(x) desc", "SUM(y)) asc"])
          end

          it 'handles expressions with NULLS FIRST/LAST' do
            expr = "COUNT(x) desc nulls last, SUM(y) asc nulls first"
            result = SqlExpressionParser.split_sql_expression(expr)
            expect(result).to eq(["COUNT(x) desc nulls last", "SUM(y) asc nulls first"])
          end
        end

        context 'with function calls and nested parentheses' do
          it 'handles function calls with parameters' do
            expr = "COUNT(x), SUM(y, z), AVG(a, b, c)"
            result = SqlExpressionParser.split_sql_expression(expr)
            expect(result).to eq(["COUNT(x)", "SUM(y, z)", "AVG(a, b, c)"])
          end

          it 'handles nested function calls' do
            expr = "COUNT(SUM(x)), AVG(MAX(y, z))"
            result = SqlExpressionParser.split_sql_expression(expr)
            expect(result).to eq(["COUNT(SUM(x))", "AVG(MAX(y, z))"])
          end

          it 'handles complex nested expressions' do
            expr = "COUNT(CASE WHEN x > 0 THEN y ELSE z END), SUM(COALESCE(a, b, c))"
            result = SqlExpressionParser.split_sql_expression(expr)
            expect(result).to eq([
              "COUNT(CASE WHEN x > 0 THEN y ELSE z END)",
              "SUM(COALESCE(a, b, c))"
            ])
          end
        end

        context 'with quoted strings' do
          it 'handles single-quoted strings' do
            expr = "name = 'John, Doe', age > 25"
            result = SqlExpressionParser.split_sql_expression(expr)
            expect(result).to eq(["name = 'John, Doe'", "age > 25"])
          end

          it 'handles double-quoted strings' do
            expr = 'title = "Hello, World!", status = "active"'
            result = SqlExpressionParser.split_sql_expression(expr)
            expect(result).to eq(['title = "Hello, World!"', 'status = "active"'])
          end

          it 'handles backtick-quoted identifiers' do
            expr = "`table`.`column`, `another`.`field`"
            result = SqlExpressionParser.split_sql_expression(expr)
            expect(result).to eq(["`table`.`column`", "`another`.`field`"])
          end

          it 'handles escaped quotes within strings' do
            expr = "name = 'John\\'s name', description = 'It\\'s great'"
            result = SqlExpressionParser.split_sql_expression(expr)
            expect(result).to eq(["name = 'John\\'s name'", "description = 'It\\'s great'"])
          end

          it 'handles doubled quotes for SQL string literals' do
            expr = "name = 'John''s name', description = 'It''s great'"
            result = SqlExpressionParser.split_sql_expression(expr)
            expect(result).to eq(["name = 'John''s name'", "description = 'It''s great'"])
          end

          it 'handles mixed quote types' do
            expr = "name = 'John', title = \"Hello\", field = `value`"
            result = SqlExpressionParser.split_sql_expression(expr)
            expect(result).to eq(["name = 'John'", 'title = "Hello"', "field = `value`"])
          end
        end

        context 'with brackets and braces' do
          it 'handles square brackets' do
            expr = "array[1], array[2, 3]"
            result = SqlExpressionParser.split_sql_expression(expr)
            expect(result).to eq(["array[1]", "array[2, 3]"])
          end

          it 'handles curly braces' do
            expr = "json_field{key}, json_field{nested, keys}"
            result = SqlExpressionParser.split_sql_expression(expr)
            expect(result).to eq(["json_field{key}", "json_field{nested, keys}"])
          end

          it 'handles mixed bracket types' do
            expr = "func(x)[1], obj{key}[2]"
            result = SqlExpressionParser.split_sql_expression(expr)
            expect(result).to eq(["func(x)[1]", "obj{key}[2]"])
          end
        end

        context 'with complex real-world scenarios' do
          it 'handles PostgreSQL JSON operators' do
            expr = "data->>'name', data->'address'->>'city'"
            result = SqlExpressionParser.split_sql_expression(expr)
            expect(result).to eq(["data->>'name'", "data->'address'->>'city'"])
          end

          it 'handles window functions' do
            expr = "ROW_NUMBER() OVER (ORDER BY name), RANK() OVER (PARTITION BY dept ORDER BY salary)"
            result = SqlExpressionParser.split_sql_expression(expr)
            expect(result).to eq([
              "ROW_NUMBER() OVER (ORDER BY name)",
              "RANK() OVER (PARTITION BY dept ORDER BY salary)"
            ])
          end

          it 'handles subqueries' do
            expr = "(SELECT COUNT(*) FROM users), (SELECT MAX(salary) FROM employees WHERE dept = 'IT')"
            result = SqlExpressionParser.split_sql_expression(expr)
            expect(result).to eq([
              "(SELECT COUNT(*) FROM users)",
              "(SELECT MAX(salary) FROM employees WHERE dept = 'IT')"
            ])
          end

          it 'handles CASE statements' do
            expr = "CASE WHEN x > 0 THEN 'positive' ELSE 'negative' END, CASE status WHEN 'A' THEN 1 WHEN 'B' THEN 2 ELSE 0 END"
            result = SqlExpressionParser.split_sql_expression(expr)
            expect(result).to eq([
              "CASE WHEN x > 0 THEN 'positive' ELSE 'negative' END",
              "CASE status WHEN 'A' THEN 1 WHEN 'B' THEN 2 ELSE 0 END"
            ])
          end
        end

        context 'with edge cases and error handling' do
          it 'handles unmatched opening parentheses' do
            expr = "COUNT(x, SUM(y"
            result = SqlExpressionParser.split_sql_expression(expr)
            expect(result).to eq(["COUNT(x, SUM(y"])
          end

          it 'handles unmatched closing parentheses' do
            expr = "COUNT(x)), SUM(y"
            result = SqlExpressionParser.split_sql_expression(expr)
            expect(result).to eq(["COUNT(x))", "SUM(y"])
          end

          it 'handles unmatched quotes' do
            expr = "name = 'John, age > 25"
            result = SqlExpressionParser.split_sql_expression(expr)
            expect(result).to eq(["name = 'John, age > 25"])
          end

          it 'handles empty parts between commas' do
            expr = "COUNT(x),, SUM(y)"
            result = SqlExpressionParser.split_sql_expression(expr)
            expect(result).to eq(["COUNT(x)", "SUM(y)"])
          end

          it 'handles trailing comma' do
            expr = "COUNT(x), SUM(y),"
            result = SqlExpressionParser.split_sql_expression(expr)
            expect(result).to eq(["COUNT(x)", "SUM(y)"])
          end

          it 'handles leading comma' do
            expr = ", COUNT(x), SUM(y)"
            result = SqlExpressionParser.split_sql_expression(expr)
            expect(result).to eq(["COUNT(x)", "SUM(y)"])
          end
        end

        context 'performance considerations' do
          it 'uses frozen constant for quote characters' do
            expect(SqlExpressionParser::QUOTE_CHARS).to be_frozen
          end

          it 'handles large expressions efficiently' do
            # Create a large expression with many nested parentheses
            large_expr = "COUNT(" + "SUM(" * 10 + "x" + ")" * 10 + ", AVG(y)"
            result = SqlExpressionParser.split_sql_expression(large_expr)
            expect(result.length).to eq(1) # The comma is inside parentheses, so it's one expression
            expect(result[0]).to start_with("COUNT(")
            expect(result[0]).to end_with(", AVG(y)")
          end

          it 'handles multiple large expressions efficiently' do
            # Create multiple large expressions separated by commas
            large_expr1 = "COUNT(" + "SUM(" * 5 + "x" + ")" * 5 + ")"
            large_expr2 = "AVG(" + "MAX(" * 5 + "y" + ")" * 5 + ")"
            large_expr = "#{large_expr1}, #{large_expr2}"
            result = SqlExpressionParser.split_sql_expression(large_expr)
            expect(result.length).to eq(2)
            expect(result[0]).to start_with("COUNT(")
            expect(result[1]).to start_with("AVG(")
          end
        end

        context 'integration with Ransack use cases' do
          it 'handles typical Ransack sort expressions' do
            expr = "users.name asc, posts.created_at desc, comments.body asc"
            result = SqlExpressionParser.split_sql_expression(expr)
            expect(result).to eq([
              "users.name asc",
              "posts.created_at desc", 
              "comments.body asc"
            ])
          end

          it 'handles Ransack association sorts' do
            expr = "articles_comments_count desc, articles_tags_name asc"
            result = SqlExpressionParser.split_sql_expression(expr)
            expect(result).to eq([
              "articles_comments_count desc",
              "articles_tags_name asc"
            ])
          end

          it 'handles Ransack custom ransacker expressions' do
            expr = "full_name asc, age_in_years desc"
            result = SqlExpressionParser.split_sql_expression(expr)
            expect(result).to eq([
              "full_name asc",
              "age_in_years desc"
            ])
          end
        end
      end
    end
  end
end 