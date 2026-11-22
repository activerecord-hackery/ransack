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
    # `pattern` is the escaped value as the predicate's formatter wraps it;
    # the default is the `cont` shape, `start` and `end` pass their own.
    shared_examples 'wildcard escaping' do |method, column_and_operator, pattern = '%\\%.\\_\\\\%'|
      it 'automatically converts integers to strings' do
        subject.parent_id_cont = 1
        expect { subject.result }.to_not raise_error
      end

      it "escapes '%', '_' and '\\\\' in value and emits an ESCAPE clause" do
        subject.send(:"#{method}=", '%._\\')
        expect(subject.result.to_sql).to include(
          "#{column_and_operator} #{quote_value(pattern)} " \
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
        RansackHelper.i_like_name do
        subject { @s }
      end

      it 'generates a case-insensitive LIKE query with value surrounded by %' do
        @s.name_i_cont = 'Ric'
        expect(@s.result.to_sql).to match /#{i_like_name} '%ric%'/
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
        RansackHelper.i_like_name(negated: true) do
        subject { @s }
      end

      it 'generates a case-insensitive NOT LIKE query with value surrounded by %' do
        @s.name_not_i_cont = 'Ric'
        expect(@s.result.to_sql).to match /#{i_like_name(negated: true)} '%ric%'/
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

    # `start` and `end` had no case-insensitive form, so once `start` became
    # `LIKE` on PostgreSQL there was no way to ask for "begins with, ignoring
    # case" at all (#1715). These mirror `i_cont`.
    describe 'i_start' do
      it_has_behavior 'wildcard escaping', :name_i_start,
        RansackHelper.i_like_name, '\\%.\\_\\\\%' do
        subject { @s }
      end

      it 'generates a case-insensitive LIKE query with value followed by %' do
        @s.name_i_start = 'Er'
        expect(@s.result.to_sql).to match /#{i_like_name} 'er%'/
      end

      it 'finds a record whose case differs from the search term' do
        person = Person.create!(name: 'Zyxwvut Qponml')
        expect(Person.ransack(name_i_start: 'zYXW').result.count).to eq 1
        expect(Person.ransack(name_start: 'zYXW').result.count).to eq 0 if dialect.postgresql?
      ensure
        person&.destroy
      end

      it 'registers the _any and _all compounds' do
        expect(Predicate.names).to include('i_start_any', 'i_start_all', 'not_i_start_any', 'not_i_start_all')
      end

      it 'keeps both halves of an _any compound case-insensitive' do
        @s.name_i_start_any = %w(Er Ri)
        expect(@s.result.to_sql).to match /#{i_like_name} 'er%'.* OR .*#{i_like_name} 'ri%'/
      end

      # Arel's does_not_match_any / _all take no case_sensitive argument, unlike
      # matches_any / _all, so Condition maps them over does_not_match by hand.
      # These are the compounds that would silently fall back to LIKE.
      it 'keeps both halves of a not_ _any compound case-insensitive' do
        @s.name_not_i_start_any = %w(Er Ri)
        expect(@s.result.to_sql).to match /#{i_like_name(negated: true)} 'er%'.* OR .*#{i_like_name(negated: true)} 'ri%'/
      end
    end

    describe 'not_i_start' do
      it_has_behavior 'wildcard escaping', :name_not_i_start,
        RansackHelper.i_like_name(negated: true), '\\%.\\_\\\\%' do
        subject { @s }
      end

      it 'generates a case-insensitive NOT LIKE query with value followed by %' do
        @s.name_not_i_start = 'Er'
        expect(@s.result.to_sql).to match /#{i_like_name(negated: true)} 'er%'/
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

    describe 'i_end' do
      it_has_behavior 'wildcard escaping', :name_i_end,
        RansackHelper.i_like_name, '%\\%.\\_\\\\' do
        subject { @s }
      end

      it 'generates a case-insensitive LIKE query with value preceded by %' do
        @s.name_i_end = 'Miller'
        expect(@s.result.to_sql).to match /#{i_like_name} '%miller'/
      end

      it 'finds a record whose case differs from the search term' do
        person = Person.create!(name: 'Zyxwvut Qponml')
        expect(Person.ransack(name_i_end: 'QPONML').result.count).to eq 1
        expect(Person.ransack(name_end: 'QPONML').result.count).to eq 0 if dialect.postgresql?
      ensure
        person&.destroy
      end

      it 'registers the _any and _all compounds' do
        expect(Predicate.names).to include('i_end_any', 'i_end_all', 'not_i_end_any', 'not_i_end_all')
      end

      it 'keeps both halves of an _all compound case-insensitive' do
        @s.name_i_end_all = %w(Er Ri)
        expect(@s.result.to_sql).to match /#{i_like_name} '%er'.* AND .*#{i_like_name} '%ri'/
      end

      it 'keeps both halves of a not_ _all compound case-insensitive' do
        @s.name_not_i_end_all = %w(Er Ri)
        expect(@s.result.to_sql).to match /#{i_like_name(negated: true)} '%er'.* AND .*#{i_like_name(negated: true)} '%ri'/
      end
    end

    describe 'not_i_end' do
      it_has_behavior 'wildcard escaping', :name_not_i_end,
        RansackHelper.i_like_name(negated: true), '%\\%.\\_\\\\' do
        subject { @s }
      end

      it 'generates a case-insensitive NOT LIKE query with value preceded by %' do
        @s.name_not_i_end = 'Miller'
        expect(@s.result.to_sql).to match /#{i_like_name(negated: true)} '%miller'/
      end
    end

    # MySQL's LIKE compares with the column's collation, and the default
    # ones ignore case. Lowering such a column changes no result but keeps a
    # prefix LIKE off the column's index, so `i_start` scanned the whole
    # table (#1811). A case-sensitive collation still needs LOWER().
    describe 'case-insensitive predicates and the column collation' do
      let(:field) { "#{quote_table_name("people")}.#{quote_column_name("name")}" }

      def sql_with_collation(collation)
        allow_any_instance_of(Ransack::ActiveRecord::Context)
          .to receive(:collation_for).and_return(collation)
        Person.ransack(name_i_start: 'Er').result.to_sql
      end

      # PostgreSQL's visitor renders the predicate as ILIKE whatever dialect
      # Ransack is told it is, so these run on the other databases.
      context 'on MySQL', unless: RansackHelper.dialect.postgresql? do
        before { Ransack.configure { |c| c.dialect = :mysql } }
        after { Ransack.configure { |c| c.dialect = nil } }

        it 'leaves a column with a case-insensitive collation bare' do
          expect(sql_with_collation('utf8mb4_0900_ai_ci')).to match /#{field} LIKE 'er%'/
          expect(sql_with_collation('utf8mb4_0900_ai_ci')).not_to include 'LOWER('
        end

        it 'lowers a column with a case-sensitive or binary collation' do
          %w(utf8mb4_bin utf8mb4_0900_as_cs).each do |collation|
            expect(sql_with_collation(collation)).to match /LOWER\(#{field}\) LIKE 'er%'/
          end
        end

        it 'lowers a column with no collation' do
          expect(sql_with_collation(nil)).to match /LOWER\(#{field}\) LIKE 'er%'/
        end
      end

      it 'is not consulted outside MySQL', unless: RansackHelper.dialect.mysql? do
        expect(sql_with_collation('utf8mb4_0900_ai_ci')).to match /#{i_like_name} 'er%'/
      end

      it 'still lowers a ransacker, whose collation is unknown', if: RansackHelper.dialect.mysql? do
        expect(Person.ransack(doubled_name_i_cont: 'Ric').result.to_sql).to include 'LOWER('
      end

      context 'with a binary-collation column', if: RansackHelper.dialect.mysql? do
        before(:all) do
          ::ActiveRecord::Base.lease_connection.create_table(:collated_codes, force: true) do |t|
            t.string :folded
            t.string :exact, collation: 'utf8mb4_bin'
            t.index :folded
          end
        end
        after(:all) { ::ActiveRecord::Base.lease_connection.drop_table(:collated_codes, if_exists: true) }
        before do
          stub_const('CollatedCode', Class.new(ApplicationRecord) { self.table_name = 'collated_codes' })
          CollatedCode.create!(folded: 'R123', exact: 'R123')
        end

        it 'matches either case, lowering only where LIKE would not' do
          folded = CollatedCode.ransack(folded_i_start: 'r1')
          exact = CollatedCode.ransack(exact_i_start: 'r1')

          expect(folded.result.to_sql).not_to include 'LOWER('
          expect(exact.result.to_sql).to include 'LOWER('
          expect(folded.result.pluck(:folded)).to eq ['R123']
          expect(exact.result.pluck(:exact)).to eq ['R123']
          expect(CollatedCode.ransack(exact_start: 'r1').result.count).to eq 0
        end
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

      # A formatter runs once per value and a String it returns is one value,
      # quoted as a whole; it cannot splice `'a','b'` into the SQL (#1553).
      # For an `in` predicate the formatter returns an Array.
      describe "with 'in' arel predicate and an array-returning formatter" do
        before do
          Ransack.configure do |c|
            c.add_predicate "in_list",
              arel_predicate: "in",
              formatter: proc { |v| v&.split(";") }
          end
        end

        it 'generates an IN list with one element per value' do
          @s.name_in_list = 'Aaron;Ernie'
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
