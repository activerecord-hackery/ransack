require 'spec_helper'

module Ransack
  TRUE_VALUES  = [true,  1, '1', 't', 'T', 'true',  'TRUE'].to_set
  FALSE_VALUES = [false, 0, '0', 'f', 'F', 'false', 'FALSE'].to_set

  describe Predicate do
    before do
      @s = Search.new(Person)
    end

    # The LIKE wildcards `%` and `_`, and the escape character itself, must be
    # escaped so they match literally. `.` is not a LIKE wildcard and is left
    # alone. The escaping only means anything because of the ESCAPE clause —
    # without it SQLite treats the backslash as an ordinary character.
    # See https://github.com/activerecord-hackery/ransack/issues/1581
    shared_examples 'wildcard escaping' do |method, column_and_operator|
      it 'automatically converts integers to strings' do
        subject.parent_id_cont = 1
        expect { subject.result }.to_not raise_error
      end

      it "escapes '%', '_' and '\\\\' in value and emits an ESCAPE clause" do
        subject.send(:"#{method}=", '%._\\')
        expect(subject.result.to_sql).to include(
          "#{column_and_operator} #{quote_value('%\\%.\\_\\\\%')} " \
          "ESCAPE #{quote_value('\\')}"
        )
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
        (RansackHelper.dialect.mysql? ? %{`people`.`name` LIKE} : %{"people"."name" LIKE}) do
        subject { @s }
      end

      it 'generates a LIKE query with value surrounded by %' do
        @s.name_cont = 'ric'
        field = "#{quote_table_name("people")}.#{quote_column_name("name")}"
        expect(@s.result.to_sql).to match /#{field} LIKE '%ric%'/
      end

      # Before 6.0 every LIKE on PostgreSQL was rendered as ILIKE, so `cont`
      # and `i_cont` were indistinguishable there (#1421).
      it 'is case-sensitive: never ILIKE, even on PostgreSQL' do
        @s.name_cont = 'Ric'
        expect(@s.result.to_sql).not_to include 'ILIKE'
      end
    end

    describe 'not_cont' do
      it_has_behavior 'wildcard escaping', :name_not_cont,
        (RansackHelper.dialect.mysql? ? %{`people`.`name` NOT LIKE} : %{"people"."name" NOT LIKE}) do
        subject { @s }
      end

      it 'generates a NOT LIKE query with value surrounded by %' do
        @s.name_not_cont = 'ric'
        field = "#{quote_table_name("people")}.#{quote_column_name("name")}"
        expect(@s.result.to_sql).to match /#{field} NOT LIKE '%ric%'/
      end
    end

    describe 'i_cont' do
      it_has_behavior 'wildcard escaping', :name_i_cont,
        (case RansackHelper.dialect.name
        when :postgresql then %{"people"."name" ILIKE}
        when :mysql      then %{LOWER(`people`.`name`) LIKE}
        else                  %{LOWER("people"."name") LIKE}
        end) do
        subject { @s }
      end

      it 'generates a LIKE query with LOWER(column) and value surrounded by %' do
        @s.name_i_cont = 'Ric'
        field = "#{quote_table_name("people")}.#{quote_column_name("name")}"
        expect(@s.result.to_sql).to match /[LOWER\(]?#{field}\)? I?LIKE '%ric%'/
      end

      # The dialect comes from the searched model's connection, so a model on
      # a second database does not get the primary database's SQL (#1407).
      it 'takes the dialect from the searched model' do
        postgresql_shaped = Class.new(::ActiveRecord::ConnectionAdapters::AbstractAdapter)
        stub_const('ActiveRecord::ConnectionAdapters::PostgreSQLAdapter', postgresql_shaped)
        allow(Person).to receive(:adapter_class).and_return(postgresql_shaped)

        @s.name_i_cont = 'Ric'
        expect(@s.result.to_sql).not_to include 'LOWER('
      end

      # A ransacker can return any Arel node, not only a column. Before 6.0
      # the lowering went through Attribute#lower, which such nodes lack, and
      # the failure was rescued into an un-lowered comparison (#1357).
      it 'lowers a ransacker expression too' do
        @s.doubled_name_i_cont = 'Ric'
        field = "#{quote_table_name("people")}.#{quote_column_name("name")}"
        if dialect.case_insensitive_like?
          expect(@s.result.to_sql).to match /#{field} \|\| #{field} ILIKE '%ric%'/
        else
          expect(@s.result.to_sql).to match /LOWER\(#{field} \|\| #{field}\) LIKE '%ric%'/
        end
      end
    end

    describe 'not_i_cont' do
      it_has_behavior 'wildcard escaping', :name_not_i_cont,
        (case RansackHelper.dialect.name
        when :postgresql then %{"people"."name" NOT ILIKE}
        when :mysql      then %{LOWER(`people`.`name`) NOT LIKE}
        else                  %{LOWER("people"."name") NOT LIKE}
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
          ::ActiveRecord::Base.lease_connection.quoted_true}/
      end

      it 'generates an inequality condition for boolean true' do
        @s.awesome_true = false
        field = "#{quote_table_name("people")}.#{quote_column_name("awesome")}"
        expect(@s.result.to_sql).to match /#{field} != #{
          ::ActiveRecord::Base.lease_connection.quoted_true}/
      end
    end

    describe 'not_true' do
      it 'generates an inequality condition for boolean true' do
        @s.awesome_not_true = true
        field = "#{quote_table_name("people")}.#{quote_column_name("awesome")}"
        expect(@s.result.to_sql).to match /#{field} != #{
          ::ActiveRecord::Base.lease_connection.quoted_true}/
      end

      it 'generates an equality condition for boolean true' do
        @s.awesome_not_true = false
        field = "#{quote_table_name("people")}.#{quote_column_name("awesome")}"
        expect(@s.result.to_sql).to match /#{field} = #{
          ::ActiveRecord::Base.lease_connection.quoted_true}/
      end
    end

    describe 'false' do
      it 'generates an equality condition for boolean false' do
        @s.awesome_false = true
        field = "#{quote_table_name("people")}.#{quote_column_name("awesome")}"
        expect(@s.result.to_sql).to match /#{field} = #{
          ::ActiveRecord::Base.lease_connection.quoted_false}/
      end

      it 'generates an inequality condition for boolean false' do
        @s.awesome_false = false
        field = "#{quote_table_name("people")}.#{quote_column_name("awesome")}"
        expect(@s.result.to_sql).to match /#{field} != #{
          ::ActiveRecord::Base.lease_connection.quoted_false}/
      end
    end

    describe 'not_false' do
      it 'generates an inequality condition for boolean false' do
        @s.awesome_not_false = true
        field = "#{quote_table_name("people")}.#{quote_column_name("awesome")}"
        expect(@s.result.to_sql).to match /#{field} != #{
          ::ActiveRecord::Base.lease_connection.quoted_false}/
      end

      it 'generates an equality condition for boolean false' do
        @s.awesome_not_false = false
        field = "#{quote_table_name("people")}.#{quote_column_name("awesome")}"
        expect(@s.result.to_sql).to match /#{field} = #{
          ::ActiveRecord::Base.lease_connection.quoted_false}/
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

      # Regression test for https://github.com/activerecord-hackery/ransack/issues/1552
      # On non-string columns the empty-string half of the comparison has no
      # meaning and gets cast to NULL, producing the always-UNKNOWN
      # `column != NULL` clause. The query should reduce to `IS NOT NULL` only.
      it 'generates only IS NOT NULL on non-string columns' do
        @s.salary_present = true
        field = "#{quote_table_name("people")}.#{quote_column_name("salary")}"
        expect(@s.result.to_sql).to match /#{field} IS NOT NULL/
        expect(@s.result.to_sql).not_to match(%r{!= NULL})
      end

      it 'generates only IS NULL on non-string columns when assigned false' do
        @s.salary_present = false
        field = "#{quote_table_name("people")}.#{quote_column_name("salary")}"
        expect(@s.result.to_sql).to match /#{field} IS NULL/
        expect(@s.result.to_sql).not_to match(%r{= NULL})
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

      # Regression test for https://github.com/activerecord-hackery/ransack/issues/1552
      it 'generates only IS NULL on non-string columns' do
        @s.salary_blank = true
        field = "#{quote_table_name("people")}.#{quote_column_name("salary")}"
        expect(@s.result.to_sql).to match /#{field} IS NULL/
        expect(@s.result.to_sql).not_to match(%r{= NULL})
      end

      it 'generates only IS NOT NULL on non-string columns when assigned false' do
        @s.salary_blank = false
        field = "#{quote_table_name("people")}.#{quote_column_name("salary")}"
        expect(@s.result.to_sql).to match /#{field} IS NOT NULL/
        expect(@s.result.to_sql).not_to match(%r{!= NULL})
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

      # Pending spec for https://github.com/activerecord-hackery/ransack/issues/1553
      # When a custom predicate uses arel_predicate: 'in' together with a formatter
      # that builds the inner SQL fragment manually (e.g. joining with "','"),
      # ActiveRecord double-escapes the single quotes, producing IN ('a'',''b')
      # instead of IN ('a', 'b').
      #
      # Marked pending because the fix direction needs a design call. See the
      # discussion on the linked issue.
      describe "with 'in' arel predicate and a string-returning formatter" do
        before do
          Ransack.configure do |c|
            c.add_predicate "in_list",
              arel_predicate: "in",
              formatter: proc { |v| v&.split(";")&.join("','") }
          end
        end

        it 'does not double-escape single quotes in the formatted value' do
          pending "https://github.com/activerecord-hackery/ransack/issues/1553"
          @s.name_in_list = "Aaron;Ernie"
          field = "#{quote_table_name("people")}.#{quote_column_name("name")}"
          expect(@s.result.to_sql).to match /#{field} IN \('Aaron', 'Ernie'\)/
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
        quoted_value = ::ActiveRecord::Base.lease_connection.quote(value)
        /#{field} #{operator} #{quoted_value}/
      end
    end

end
