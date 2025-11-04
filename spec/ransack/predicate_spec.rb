require 'spec_helper'

module Ransack
  TRUE_VALUES  = [true,  1, '1', 't', 'T', 'true',  'TRUE'].to_set
  FALSE_VALUES = [false, 0, '0', 'f', 'F', 'false', 'FALSE'].to_set

  describe Predicate do
    before do
      @s = Search.new(Person)
    end

    shared_examples 'wildcard escaping' do |method, regexp|
      it 'automatically converts integers to strings' do
        subject.parent_id_cont = 1
        expect { subject.result }.to_not raise_error
      end

      it "escapes '%', '.', '_' and '\\\\' in value" do
        subject.send(:"#{method}=", '%._\\')
        expect(subject.result.to_sql).to match(regexp)
      end
    end

    describe 'eq' do
      it 'generates an equality condition for boolean true values' do
        test_boolean_equality_for(true)
      end

      it 'generates an equality condition for boolean false values' do
        test_boolean_equality_for(false)
      end

      it 'does not generate a condition for nil' do
        @s.awesome_eq = nil
        expect(@s.result.to_sql).not_to match /WHERE/
      end

      it 'generates a = condition with a huge integer value' do
        val = 123456789012345678901
        @s.salary_eq = val
        field = "#{quote_table_name("people")}.#{quote_column_name("salary")}"
        expect(@s.result.to_sql).to match /#{field} = #{val}/
      end
    end

    describe 'lteq' do
      it 'generates a <= condition with an integer column' do
        val = 1000
        @s.salary_lteq = val
        field = "#{quote_table_name("people")}.#{quote_column_name("salary")}"
        expect(@s.result.to_sql).to match /#{field} <= #{val}/
      end

      it 'generates a <= condition with a string column' do
        val = 'jane@doe.com'
        @s.email_lteq = val
        field = "#{quote_table_name("people")}.#{quote_column_name("email")}"
        expect(@s.result.to_sql).to match /#{field} <= '#{val}'/
      end

      it 'does not generate a condition for nil' do
        @s.salary_lteq = nil
        expect(@s.result.to_sql).not_to match /WHERE/
      end

      it 'generates a <= condition with a huge integer value' do
        val = 123456789012345678901
        @s.salary_lteq = val
        field = "#{quote_table_name("people")}.#{quote_column_name("salary")}"
        expect(@s.result.to_sql).to match /#{field} <= #{val}/
      end
    end

    describe 'lt' do
      it 'generates a < condition with an integer column' do
        val = 2000
        @s.salary_lt = val
        field = "#{quote_table_name("people")}.#{quote_column_name("salary")}"
        expect(@s.result.to_sql).to match /#{field} < #{val}/
      end

      it 'generates a < condition with a string column' do
        val = 'jane@doe.com'
        @s.email_lt = val
        field = "#{quote_table_name("people")}.#{quote_column_name("email")}"
        expect(@s.result.to_sql).to match /#{field} < '#{val}'/
      end

      it 'does not generate a condition for nil' do
        @s.salary_lt = nil
        expect(@s.result.to_sql).not_to match /WHERE/
      end

      it 'generates a = condition with a huge integer value' do
        val = 123456789012345678901
        @s.salary_lt = val
        field = "#{quote_table_name("people")}.#{quote_column_name("salary")}"
        expect(@s.result.to_sql).to match /#{field} < #{val}/
      end
    end

    describe 'gteq' do
      it 'generates a >= condition with an integer column' do
        val = 300
        @s.salary_gteq = val
        field = "#{quote_table_name("people")}.#{quote_column_name("salary")}"
        expect(@s.result.to_sql).to match /#{field} >= #{val}/
      end

      it 'generates a >= condition with a string column' do
        val = 'jane@doe.com'
        @s.email_gteq = val
        field = "#{quote_table_name("people")}.#{quote_column_name("email")}"
        expect(@s.result.to_sql).to match /#{field} >= '#{val}'/
      end

      it 'does not generate a condition for nil' do
        @s.salary_gteq = nil
        expect(@s.result.to_sql).not_to match /WHERE/
      end

      it 'generates a >= condition with a huge integer value' do
        val = 123456789012345678901
        @s.salary_gteq = val
        field = "#{quote_table_name("people")}.#{quote_column_name("salary")}"
        expect(@s.result.to_sql).to match /#{field} >= #{val}/
      end
    end

    describe 'gt' do
      it 'generates a > condition with an integer column' do
        val = 400
        @s.salary_gt = val
        field = "#{quote_table_name("people")}.#{quote_column_name("salary")}"
        expect(@s.result.to_sql).to match /#{field} > #{val}/
      end

      it 'generates a > condition with a string column' do
        val = 'jane@doe.com'
        @s.email_gt = val
        field = "#{quote_table_name("people")}.#{quote_column_name("email")}"
        expect(@s.result.to_sql).to match /#{field} > '#{val}'/
      end

      it 'does not generate a condition for nil' do
        @s.salary_gt = nil
        expect(@s.result.to_sql).not_to match /WHERE/
      end

      it 'generates a > condition with a huge integer value' do
        val = 123456789012345678901
        @s.salary_gt = val
        field = "#{quote_table_name("people")}.#{quote_column_name("salary")}"
        expect(@s.result.to_sql).to match /#{field} > #{val}/
      end
    end

    describe 'cont' do
      it_has_behavior 'wildcard escaping', :name_cont,
        (case ActiveRecord::Base.connection.adapter_name
        when "PostGIS", "PostgreSQL"
          /"people"."name" ILIKE '%\\%\\.\\_\\\\%'/
        when "Mysql2"
          /`people`.`name` LIKE '%\\\\%.\\\\_\\\\\\\\%'/
        else
         /"people"."name" LIKE '%%._\\%'/
        end) do
        subject { @s }
      end

      it 'generates a LIKE query with value surrounded by %' do
        @s.name_cont = 'ric'
        field = "#{quote_table_name("people")}.#{quote_column_name("name")}"
        expect(@s.result.to_sql).to match /#{field} I?LIKE '%ric%'/
      end
    end

    describe 'not_cont' do
      it_has_behavior 'wildcard escaping', :name_not_cont,
        (case ActiveRecord::Base.connection.adapter_name
        when "PostGIS", "PostgreSQL"
          /"people"."name" NOT ILIKE '%\\%\\.\\_\\\\%'/
        when  "Mysql2"
          /`people`.`name` NOT LIKE '%\\\\%.\\\\_\\\\\\\\%'/
        else
         /"people"."name" NOT LIKE '%%._\\%'/
        end) do
        subject { @s }
      end

      it 'generates a NOT LIKE query with value surrounded by %' do
        @s.name_not_cont = 'ric'
        field = "#{quote_table_name("people")}.#{quote_column_name("name")}"
        expect(@s.result.to_sql).to match /#{field} NOT I?LIKE '%ric%'/
      end
    end

    describe 'i_cont' do
      it_has_behavior 'wildcard escaping', :name_i_cont,
        (case ActiveRecord::Base.connection.adapter_name
        when "PostGIS"
          /LOWER\("people"."name"\) ILIKE '%\\%\\.\\_\\\\%'/
        when "PostgreSQL"
          /"people"."name" ILIKE '%\\%\\.\\_\\\\%'/
        when "Mysql2"
          /LOWER\(`people`.`name`\) LIKE '%\\\\%.\\\\_\\\\\\\\%'/
        else
         /LOWER\("people"."name"\) LIKE '%%._\\%'/
        end) do
        subject { @s }
      end

      it 'generates a LIKE query with LOWER(column) and value surrounded by %' do
        @s.name_i_cont = 'Ric'
        field = "#{quote_table_name("people")}.#{quote_column_name("name")}"
        expect(@s.result.to_sql).to match /[LOWER\(]?#{field}\)? I?LIKE '%ric%'/
      end
    end

    describe 'not_i_cont' do
      it_has_behavior 'wildcard escaping', :name_not_i_cont,
        (case ActiveRecord::Base.connection.adapter_name
        when "PostGIS"
          /LOWER\("people"."name"\) NOT ILIKE '%\\%\\.\\_\\\\%'/
        when "PostgreSQL"
          /"people"."name" NOT ILIKE '%\\%\\.\\_\\\\%'/
        when "Mysql2"
          /LOWER\(`people`.`name`\) NOT LIKE '%\\\\%.\\\\_\\\\\\\\%'/
        else
         /LOWER\("people"."name"\) NOT LIKE '%%._\\%'/
        end) do
        subject { @s }
      end

      it 'generates a NOT LIKE query with LOWER(column) and value surrounded by %' do
        @s.name_not_i_cont = 'Ric'
        field = "#{quote_table_name("people")}.#{quote_column_name("name")}"
        expect(@s.result.to_sql).to match /[LOWER\(]?#{field}\)? NOT I?LIKE '%ric%'/
      end
    end

    describe 'start' do
      it 'generates a LIKE query with value followed by %' do
        @s.name_start = 'Er'
        field = "#{quote_table_name("people")}.#{quote_column_name("name")}"
        expect(@s.result.to_sql).to match /#{field} I?LIKE 'Er%'/
      end

      it "works with attribute names ending with '_start'" do
        @s.new_start_start = 'hEy'
        field = "#{quote_table_name("people")}.#{quote_column_name("new_start")}"
        expect(@s.result.to_sql).to match /#{field} I?LIKE 'hEy%'/
      end

      it "works with attribute names ending with '_end'" do
        @s.stop_end_start = 'begin'
        field = "#{quote_table_name("people")}.#{quote_column_name("stop_end")}"
        expect(@s.result.to_sql).to match /#{field} I?LIKE 'begin%'/
      end
    end

    describe 'not_start' do
      it 'generates a NOT LIKE query with value followed by %' do
        @s.name_not_start = 'Eri'
        field = "#{quote_table_name("people")}.#{quote_column_name("name")}"
        expect(@s.result.to_sql).to match /#{field} NOT I?LIKE 'Eri%'/
      end

      it "works with attribute names ending with '_start'" do
        @s.new_start_not_start = 'hEy'
        field = "#{quote_table_name("people")}.#{quote_column_name("new_start")}"
        expect(@s.result.to_sql).to match /#{field} NOT I?LIKE 'hEy%'/
      end

      it "works with attribute names ending with '_end'" do
        @s.stop_end_not_start = 'begin'
        field = "#{quote_table_name("people")}.#{quote_column_name("stop_end")}"
        expect(@s.result.to_sql).to match /#{field} NOT I?LIKE 'begin%'/
      end
    end

    describe 'end' do
      it 'generates a LIKE query with value preceded by %' do
        @s.name_end = 'Miller'
        field = "#{quote_table_name("people")}.#{quote_column_name("name")}"
        expect(@s.result.to_sql).to match /#{field} I?LIKE '%Miller'/
      end

      it "works with attribute names ending with '_start'" do
        @s.new_start_end = 'finish'
        field = "#{quote_table_name("people")}.#{quote_column_name("new_start")}"
        expect(@s.result.to_sql).to match /#{field} I?LIKE '%finish'/
      end

      it "works with attribute names ending with '_end'" do
        @s.stop_end_end = 'Ending'
        field = "#{quote_table_name("people")}.#{quote_column_name("stop_end")}"
        expect(@s.result.to_sql).to match /#{field} I?LIKE '%Ending'/
      end
    end

    describe 'not_end' do
      it 'generates a NOT LIKE query with value preceded by %' do
        @s.name_not_end = 'Miller'
        field = "#{quote_table_name("people")}.#{quote_column_name("name")}"
        expect(@s.result.to_sql).to match /#{field} NOT I?LIKE '%Miller'/
      end

      it "works with attribute names ending with '_start'" do
        @s.new_start_not_end = 'finish'
        field = "#{quote_table_name("people")}.#{quote_column_name("new_start")}"
        expect(@s.result.to_sql).to match /#{field} NOT I?LIKE '%finish'/
      end

      it "works with attribute names ending with '_end'" do
        @s.stop_end_not_end = 'Ending'
        field = "#{quote_table_name("people")}.#{quote_column_name("stop_end")}"
        expect(@s.result.to_sql).to match /#{field} NOT I?LIKE '%Ending'/
      end
    end

    describe 'true' do
      it 'generates an equality condition for boolean true' do
        @s.awesome_true = true
        field = "#{quote_table_name("people")}.#{quote_column_name("awesome")}"
        expect(@s.result.to_sql).to match /#{field} = #{
          ActiveRecord::Base.connection.quoted_true}/
      end

      it 'generates an inequality condition for boolean true' do
        @s.awesome_true = false
        field = "#{quote_table_name("people")}.#{quote_column_name("awesome")}"
        expect(@s.result.to_sql).to match /#{field} != #{
          ActiveRecord::Base.connection.quoted_true}/
      end
    end

    describe 'not_true' do
      it 'generates an inequality condition for boolean true' do
        @s.awesome_not_true = true
        field = "#{quote_table_name("people")}.#{quote_column_name("awesome")}"
        expect(@s.result.to_sql).to match /#{field} != #{
          ActiveRecord::Base.connection.quoted_true}/
      end

      it 'generates an equality condition for boolean true' do
        @s.awesome_not_true = false
        field = "#{quote_table_name("people")}.#{quote_column_name("awesome")}"
        expect(@s.result.to_sql).to match /#{field} = #{
          ActiveRecord::Base.connection.quoted_true}/
      end
    end

    describe 'false' do
      it 'generates an equality condition for boolean false' do
        @s.awesome_false = true
        field = "#{quote_table_name("people")}.#{quote_column_name("awesome")}"
        expect(@s.result.to_sql).to match /#{field} = #{
          ActiveRecord::Base.connection.quoted_false}/
      end

      it 'generates an inequality condition for boolean false' do
        @s.awesome_false = false
        field = "#{quote_table_name("people")}.#{quote_column_name("awesome")}"
        expect(@s.result.to_sql).to match /#{field} != #{
          ActiveRecord::Base.connection.quoted_false}/
      end
    end

    describe 'not_false' do
      it 'generates an inequality condition for boolean false' do
        @s.awesome_not_false = true
        field = "#{quote_table_name("people")}.#{quote_column_name("awesome")}"
        expect(@s.result.to_sql).to match /#{field} != #{
          ActiveRecord::Base.connection.quoted_false}/
      end

      it 'generates an equality condition for boolean false' do
        @s.awesome_not_false = false
        field = "#{quote_table_name("people")}.#{quote_column_name("awesome")}"
        expect(@s.result.to_sql).to match /#{field} = #{
          ActiveRecord::Base.connection.quoted_false}/
      end
    end

    describe 'null' do
      it 'generates a value IS NULL query' do
        @s.name_null = true
        field = "#{quote_table_name("people")}.#{quote_column_name("name")}"
        expect(@s.result.to_sql).to match /#{field} IS NULL/
      end

      it 'generates a value IS NOT NULL query when assigned false' do
        @s.name_null = false
        field = "#{quote_table_name("people")}.#{quote_column_name("name")}"
        expect(@s.result.to_sql).to match /#{field} IS NOT NULL/
      end
    end

    describe 'not_null' do
      it 'generates a value IS NOT NULL query' do
        @s.name_not_null = true
        field = "#{quote_table_name("people")}.#{quote_column_name("name")}"
        expect(@s.result.to_sql).to match /#{field} IS NOT NULL/
      end

      it 'generates a value IS NULL query when assigned false' do
        @s.name_not_null = false
        field = "#{quote_table_name("people")}.#{quote_column_name("name")}"
        expect(@s.result.to_sql).to match /#{field} IS NULL/
      end

      describe 'with association query' do
        it 'generates a value IS NOT NULL query' do
          @s.comments_id_not_null = true
          sql = @s.result.to_sql
          parent_field = "#{quote_table_name("people")}.#{quote_column_name("id")}"
          expect(sql).to match /#{parent_field} IN/
          field = "#{quote_table_name("comments")}.#{quote_column_name("id")}"
          expect(sql).to match /#{field} IS NOT NULL/
          expect(sql).not_to match /AND NOT/
        end

        it 'generates a value IS NULL query when assigned false' do
          @s.comments_id_not_null = false
          sql = @s.result.to_sql
          parent_field = "#{quote_table_name("people")}.#{quote_column_name("id")}"
          expect(sql).to match /#{parent_field} NOT IN/
          field = "#{quote_table_name("comments")}.#{quote_column_name("id")}"
          expect(sql).to match /#{field} IS NULL/
          expect(sql).to match /AND NOT/
        end
      end
    end

    describe 'present' do
      it %q[generates a value IS NOT NULL AND value != '' query] do
        @s.name_present = true
        field = "#{quote_table_name("people")}.#{quote_column_name("name")}"
        expect(@s.result.to_sql).to match /#{field} IS NOT NULL AND #{field} != ''/
      end

      it %q[generates a value IS NULL OR value = '' query when assigned false] do
        @s.name_present = false
        field = "#{quote_table_name("people")}.#{quote_column_name("name")}"
        expect(@s.result.to_sql).to match /#{field} IS NULL OR #{field} = ''/
      end
    end

    describe 'blank' do
      it %q[generates a value IS NULL OR value = '' query] do
        @s.name_blank = true
        field = "#{quote_table_name("people")}.#{quote_column_name("name")}"
        expect(@s.result.to_sql).to match /#{field} IS NULL OR #{field} = ''/
      end

      it %q[generates a value IS NOT NULL AND value != '' query when assigned false] do
        @s.name_blank = false
        field = "#{quote_table_name("people")}.#{quote_column_name("name")}"
        expect(@s.result.to_sql).to match /#{field} IS NOT NULL AND #{field} != ''/
      end
    end

    describe 'length_eq' do
      it 'generates a LENGTH(column) = value condition' do
        @s.name_length_eq = 4
        field = "#{quote_table_name("people")}.#{quote_column_name("name")}"
        expect(@s.result.to_sql).to match /(CHAR_LENGTH|LENGTH)\(#{field}\) = 4/
      end

      it 'does not generate a condition for nil' do
        @s.name_length_eq = nil
        expect(@s.result.to_sql).not_to match /WHERE/
      end

      it "works with attribute names containing 'length'" do
        @s.length_field_length_eq = 8
        field = "#{quote_table_name("people")}.#{quote_column_name("length_field")}"
        expect(@s.result.to_sql).to match /(CHAR_LENGTH|LENGTH)\(#{field}\) = 8/
      end
    end

    describe 'length_lt' do
      it 'generates a LENGTH(column) < value condition' do
        @s.name_length_lt = 5
        field = "#{quote_table_name("people")}.#{quote_column_name("name")}"
        expect(@s.result.to_sql).to match /(CHAR_LENGTH|LENGTH)\(#{field}\) < 5/
      end

      it 'does not generate a condition for nil' do
        @s.name_length_lt = nil
        expect(@s.result.to_sql).not_to match /WHERE/
      end
    end

    describe 'length_lteq' do
      it 'generates a LENGTH(column) <= value condition' do
        @s.name_length_lteq = 4
        field = "#{quote_table_name("people")}.#{quote_column_name("name")}"
        expect(@s.result.to_sql).to match /(CHAR_LENGTH|LENGTH)\(#{field}\) <= 4/
      end

      it 'does not generate a condition for nil' do
        @s.name_length_lteq = nil
        expect(@s.result.to_sql).not_to match /WHERE/
      end

      it "works with attribute names containing 'length'" do
        @s.length_field_length_lteq = 10
        field = "#{quote_table_name("people")}.#{quote_column_name("length_field")}"
        expect(@s.result.to_sql).to match /(CHAR_LENGTH|LENGTH)\(#{field}\) <= 10/
      end

      it "works with attribute names starting with 'length'" do
        @s.length_of_name_length_lteq = 5
        field = "#{quote_table_name("people")}.#{quote_column_name("length_of_name")}"
        expect(@s.result.to_sql).to match /(CHAR_LENGTH|LENGTH)\(#{field}\) <= 5/
      end
    end

    describe 'length_gt' do
      it 'generates a LENGTH(column) > value condition' do
        # Use email instead of name to avoid conflict with name_length column
        @s.email_length_gt = 10
        field = "#{quote_table_name("people")}.#{quote_column_name("email")}"
        expect(@s.result.to_sql).to match /(CHAR_LENGTH|LENGTH)\(#{field}\) > 10/
      end

      it 'does not generate a condition for nil' do
        @s.email_length_gt = nil
        expect(@s.result.to_sql).not_to match /WHERE/
      end
    end

    describe 'length_gteq' do
      it 'generates a LENGTH(column) >= value condition' do
        # Use email instead of name to avoid conflict with name_length column
        @s.email_length_gteq = 10
        field = "#{quote_table_name("people")}.#{quote_column_name("email")}"
        expect(@s.result.to_sql).to match /(CHAR_LENGTH|LENGTH)\(#{field}\) >= 10/
      end

      it 'does not generate a condition for nil' do
        @s.email_length_gteq = nil
        expect(@s.result.to_sql).not_to match /WHERE/
      end
    end

    context "defining custom predicates" do
      describe "with 'not_in' arel predicate" do
        before do
          Ransack.configure { |c| c.add_predicate "not_in_csv", arel_predicate: "not_in", formatter: proc { |v| v.split(",") } }
        end

        it 'generates a value IS NOT NULL query' do
          @s.name_not_in_csv = ["a", "b"]
          field = "#{quote_table_name("people")}.#{quote_column_name("name")}"
          expect(@s.result.to_sql).to match /#{field} NOT IN \('a', 'b'\)/
        end
      end
    end

    private

      def test_boolean_equality_for(boolean_value)
        query = expected_query(boolean_value)
        test_values_for(boolean_value).each do |value|
          s = Search.new(Person, awesome_eq: value)
          expect(s.result.to_sql).to match query
        end
      end

      def test_values_for(boolean_value)
        case boolean_value
        when true
          TRUE_VALUES
        when false
          FALSE_VALUES
        end
      end

      def expected_query(value, attribute = 'awesome', operator = '=')
        field = "#{quote_table_name("people")}.#{quote_column_name(attribute)}"
        quoted_value = ActiveRecord::Base.connection.quote(value)
        /#{field} #{operator} #{quoted_value}/
      end
    end

end
