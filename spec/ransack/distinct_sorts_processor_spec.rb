require 'spec_helper'

module Ransack
  describe DistinctSortsProcessor do
    let(:search) { Search.new(Person) }
    let(:query) { Person.ransack.result }
    let(:sorts) { [] }
    let(:processor) { DistinctSortsProcessor.new(search, query, sorts) }

    # Mock SecureRandom to return predictable values for testing
    before do
      allow(SecureRandom).to receive(:hex).with(8).and_return('abc123')
    end

    def create_distinct_query
      Person.ransack.result(distinct: true)
    end

    describe '.should_process?' do
      context 'when query has distinct and sorts' do
        let(:query) { create_distinct_query }
        let(:sorts) { ['name ASC'] }

        it 'returns true' do
          expect(DistinctSortsProcessor.should_process?(query, sorts)).to be true
        end
      end

      context 'when query has distinct but no sorts' do
        let(:query) { create_distinct_query }
        let(:sorts) { [] }

        it 'returns false' do
          expect(DistinctSortsProcessor.should_process?(query, sorts)).to be false
        end
      end

      context 'when query has sorts but no distinct' do
        let(:query) { Person.ransack.result }
        let(:sorts) { ['name ASC'] }

        it 'returns false' do
          expect(DistinctSortsProcessor.should_process?(query, sorts)).to be false
        end
      end

      context 'when query has neither distinct nor sorts' do
        let(:query) { Person.ransack.result }
        let(:sorts) { [] }

        it 'returns false' do
          expect(DistinctSortsProcessor.should_process?(query, sorts)).to be false
        end
      end
    end

    describe '#initialize' do
      it 'sets search, query, and sorts attributes' do
        expect(processor.search).to eq(search)
        expect(processor.query).to eq(query)
        expect(processor.sorts).to eq(sorts)
      end
    end

    describe '#process!' do
      let(:query) { create_distinct_query }
      let(:sorts) { ['name ASC', 'created_at DESC'] }

      it 'calls all required processing methods' do
        processed_sorts = [{ original_sort: 'name ASC', alias_name: 'alias_123' }]
        expect(processor).to receive(:process_sorts).and_return(processed_sorts)
        expect(processor).to receive(:add_necessary_selects).with(processed_sorts)
        expect(processor).to receive(:update_order_values).with(processed_sorts)

        processor.process!
      end

      it 'modifies the query in place' do
        original_select_values = query.select_values.dup
        original_order_values = query.order_values.dup

        processor.process!

        expect(query.select_values).not_to eq(original_select_values)
        expect(query.order_values).not_to eq(original_order_values)
      end

      it 'returns early when sorts are empty' do
        processor_with_empty_sorts = DistinctSortsProcessor.new(search, query, [])
        expect(processor_with_empty_sorts).not_to receive(:process_sorts)

        processor_with_empty_sorts.process!
      end

      it 'returns early when processed_sorts is empty' do
        allow(processor).to receive(:process_sorts).and_return([])
        expect(processor).not_to receive(:add_necessary_selects)
        expect(processor).not_to receive(:update_order_values)

        processor.process!
      end
    end

    describe '#process_sorts' do
      let(:sorts) { ['name ASC', 'created_at DESC'] }

      it 'returns an array of processed sort objects' do
        result = processor.send(:process_sorts)
        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
        expect(result.first).to include(:original_sort)
      end

      it 'handles empty sorts array' do
        processor_with_empty_sorts = DistinctSortsProcessor.new(search, query, [])
        result = processor_with_empty_sorts.send(:process_sorts)
        expect(result).to eq([])
      end
    end

    describe '#process_sort' do
      context 'with string sort containing multiple expressions' do
        let(:sort) { 'name ASC, email DESC' }

        it 'splits and processes multiple sort expressions' do
          allow(processor).to receive(:split_sql_expression).and_return(['name ASC', 'email DESC'])
          allow(processor).to receive(:process_single_sort).and_return(
            { original_sort: 'name ASC' },
            { original_sort: 'email DESC' }
          )

          result = processor.send(:process_sort, sort)
          expect(result).to eq([
                                 { original_sort: 'name ASC' },
                                 { original_sort: 'email DESC' }
                               ])
        end
      end

      context 'with non-string sort' do
        let(:sort) { Person.arel_table[:name].asc }

        it 'processes single sort directly' do
          allow(processor).to receive(:process_single_sort).and_return({ original_sort: sort })

          result = processor.send(:process_sort, sort)
          expect(result).to eq({ original_sort: sort })
        end
      end
    end

    describe '#process_single_sort' do
      context 'with Arel ordering node' do
        let(:sort) { Person.arel_table[:name].asc }

        it 'creates a processed sort object when not using SELECT *' do
          allow(query).to receive(:select_values).and_return(['id'])
          allow(processor).to receive(:find_existing_select_alias).and_return(nil)

          result = processor.send(:process_single_sort, sort)
          expect(result).to include(:original_sort, :alias_name, :select_value)
          expect(result[:original_sort]).to eq(sort)
          expect(result[:alias_name]).to eq('alias_abc123')
        end

        it 'returns original sort when column should be skipped' do
          allow(query).to receive(:select_values).and_return([])
          allow(search.klass).to receive(:column_names).and_return(['name', 'email'])
          allow(search.klass).to receive(:table_name).and_return('people')
          allow(processor).to receive(:find_existing_select_alias).and_return(nil)

          result = processor.send(:process_single_sort, sort)
          expect(result).to include(:original_sort)
          expect(result[:original_sort]).to eq(sort)
          expect(result).not_to include(:alias_name, :select_value)
        end

        it 'returns original sort when existing alias is found' do
          allow(processor).to receive(:find_existing_select_alias).and_return('existing_alias')

          result = processor.send(:process_single_sort, sort)
          expect(result).to include(:original_sort)
          expect(result[:original_sort]).to eq(sort)
          expect(result).not_to include(:alias_name, :select_value)
        end

        it 'returns original sort when select_value is nil' do
          allow(processor).to receive(:find_existing_select_alias).and_return(nil)
          allow(processor).to receive(:build_select_value).and_return(nil)

          result = processor.send(:process_single_sort, sort)
          expect(result).to include(:original_sort)
          expect(result[:original_sort]).to eq(sort)
          expect(result).not_to include(:alias_name, :select_value)
        end
      end

      context 'with string sort' do
        let(:sort) { 'name ASC' }

        it 'creates a processed sort object' do
          allow(processor).to receive(:find_existing_select_alias).and_return(nil)

          result = processor.send(:process_single_sort, sort)
          expect(result).to include(:original_sort, :alias_name, :select_value)
          expect(result[:original_sort]).to eq(sort)
          expect(result[:alias_name]).to eq('alias_abc123')
        end

        it 'handles complex sort strings with NULLS' do
          complex_sort = 'name ASC NULLS LAST'
          allow(processor).to receive(:find_existing_select_alias).and_return(nil)

          result = processor.send(:process_single_sort, complex_sort)
          expect(result[:select_value]).to be_a(Arel::Nodes::SqlLiteral)
        end
      end

      context 'with other types' do
        it 'returns original sort for unsupported types' do
          result = processor.send(:process_single_sort, 123)
          expect(result).to include(:original_sort)
          expect(result[:original_sort]).to eq(123)
          expect(result).not_to include(:alias_name, :select_value)
        end
      end
    end

    describe '#extract_sort' do
      context 'with Arel ordering node containing Arel attribute' do
        let(:sort) { Person.arel_table[:name].asc }

        it 'extracts column name' do
          result = processor.send(:extract_sort, sort)
          expect(result).to eq('name')
        end
      end

      context 'with Arel ordering node containing SqlLiteral' do
        let(:sort) { Arel::Nodes::SqlLiteral.new('COUNT(*)').asc }

        it 'extracts sql literal' do
          result = processor.send(:extract_sort, sort)
          expect(result).to eq('COUNT(*)')
        end
      end

      context 'with Arel ordering node containing other expression' do
        let(:sort) { Arel::Nodes::Addition.new(1, 2).asc }

        it 'extracts sql representation' do
          result = processor.send(:extract_sort, sort)
          expect(result).to be_a(String)
        end
      end

      context 'with string sort' do
        it 'returns the string as is' do
          result = processor.send(:extract_sort, 'name ASC')
          expect(result).to eq('name ASC')
        end
      end

      context 'with other types' do
        it 'returns nil' do
          result = processor.send(:extract_sort, 123)
          expect(result).to be_nil
        end
      end
    end

    describe '#extract_sort_expression' do
      context 'with Arel ordering node' do
        let(:sort) { Person.arel_table[:name].asc }

        it 'extracts column name for Arel attributes' do
          result = processor.send(:extract_sort_expression, sort)
          expect(result).to eq('name')
        end
      end

      context 'with string sort' do
        it 'removes ORDER BY clauses' do
          result = processor.send(:extract_sort_expression, 'name ASC NULLS LAST')
          expect(result).to eq('name')
        end

        it 'handles sort without ORDER BY clauses' do
          result = processor.send(:extract_sort_expression, 'name')
          expect(result).to eq('name')
        end
      end

      context 'with other types' do
        it 'returns nil' do
          result = processor.send(:extract_sort_expression, 123)
          expect(result).to be_nil
        end
      end
    end

    describe '#remove_order_by_clauses' do
      it 'removes ORDER BY clauses correctly' do
        expect(processor.send(:remove_order_by_clauses, 'name ASC')).to eq('name')
        expect(processor.send(:remove_order_by_clauses, 'name DESC')).to eq('name')
        expect(processor.send(:remove_order_by_clauses, 'name ASC NULLS FIRST')).to eq('name')
        expect(processor.send(:remove_order_by_clauses, 'name DESC NULLS LAST')).to eq('name')
        expect(processor.send(:remove_order_by_clauses, 'name')).to eq('name')
      end

      it 'handles case insensitive patterns' do
        expect(processor.send(:remove_order_by_clauses, 'name asc')).to eq('name')
        expect(processor.send(:remove_order_by_clauses, 'name desc')).to eq('name')
        expect(processor.send(:remove_order_by_clauses, 'name Asc Nulls Last')).to eq('name')
      end
    end

    describe '#generate_alias_name' do
      it 'generates unique alias names' do
        allow(SecureRandom).to receive(:hex).with(8).and_return('abc123', 'def456')

        alias1 = processor.send(:generate_alias_name)
        alias2 = processor.send(:generate_alias_name)

        expect(alias1).to start_with('alias_')
        expect(alias2).to start_with('alias_')
        expect(alias1).not_to eq(alias2)
      end

      it 'uses SecureRandom for uniqueness' do
        expect(SecureRandom).to receive(:hex).with(8).and_return('abc123')
        alias_name = processor.send(:generate_alias_name)
        expect(alias_name).to eq('alias_abc123')
      end
    end

    describe '#build_select_value' do
      let(:alias_name) { 'alias_abc123' }

      context 'with Arel ordering node' do
        let(:sort) { Person.arel_table[:name].asc }

        it 'builds select value when column should not be skipped' do
          allow(processor).to receive(:should_skip_column?).and_return(false)
          allow(processor).to receive(:extract_sort_expression).and_return('name')

          result = processor.send(:build_select_value, sort, alias_name)
          expect(result).to be_a(Arel::Nodes::SqlLiteral)
          expect(result.to_s).to include('name AS alias_abc123')
        end

        it 'returns nil when column should be skipped' do
          allow(processor).to receive(:should_skip_column?).and_return(true)

          result = processor.send(:build_select_value, sort, alias_name)
          expect(result).to be_nil
        end
      end

      context 'with string sort' do
        let(:sort) { 'name ASC' }

        it 'builds select value' do
          allow(processor).to receive(:extract_sort_expression).and_return('name')

          result = processor.send(:build_select_value, sort, alias_name)
          expect(result).to be_a(Arel::Nodes::SqlLiteral)
          expect(result.to_s).to include('name AS alias_abc123')
        end

        it 'returns nil when expression is nil' do
          allow(processor).to receive(:extract_sort_expression).and_return(nil)

          result = processor.send(:build_select_value, sort, alias_name)
          expect(result).to be_nil
        end
      end

      context 'with other types' do
        it 'returns nil' do
          result = processor.send(:build_select_value, 123, alias_name)
          expect(result).to be_nil
        end
      end
    end

    describe '#should_skip_column?' do
      let(:column_name) { 'name' }
      let(:relation_name) { 'people' }

      context 'when using SELECT * and column exists in model' do
        before do
          allow(query).to receive(:select_values).and_return([])
          allow(search.klass).to receive(:column_names).and_return(['name', 'email'])
          allow(search.klass).to receive(:table_name).and_return('people')
        end

        it 'returns true' do
          expect(processor.send(:should_skip_column?, column_name, relation_name)).to be true
        end
      end

      context 'when not using SELECT *' do
        before do
          allow(query).to receive(:select_values).and_return(['id'])
        end

        it 'returns false' do
          expect(processor.send(:should_skip_column?, column_name, relation_name)).to be false
        end
      end

      context 'when column does not exist in model' do
        before do
          allow(query).to receive(:select_values).and_return([])
          allow(search.klass).to receive(:column_names).and_return(['email'])
          allow(search.klass).to receive(:table_name).and_return('people')
        end

        it 'returns false' do
          expect(processor.send(:should_skip_column?, column_name, relation_name)).to be false
        end
      end

      context 'when relation name does not match table name' do
        before do
          allow(query).to receive(:select_values).and_return([])
          allow(search.klass).to receive(:column_names).and_return(['name'])
          allow(search.klass).to receive(:table_name).and_return('users')
        end

        it 'returns false' do
          expect(processor.send(:should_skip_column?, column_name, relation_name)).to be false
        end
      end
    end

    describe '#find_existing_select_alias' do
      let(:sort) { 'name ASC' }

      it 'finds existing alias when sort expression exists in SELECT' do
        allow(query).to receive(:select_values).and_return([Arel.sql('name AS existing_alias')])
        allow(processor).to receive(:extract_sort_expression).and_return('name')
        allow(processor).to receive(:matches_select_expression?).and_return(true)
        allow(processor).to receive(:extract_alias_from_select).and_return('existing_alias')

        result = processor.send(:find_existing_select_alias, sort)
        expect(result).to eq('existing_alias')
      end

      it 'returns nil when no matching alias is found' do
        allow(query).to receive(:select_values).and_return([Arel.sql('email AS email_alias')])
        allow(processor).to receive(:extract_sort_expression).and_return('name')
        allow(processor).to receive(:matches_select_expression?).and_return(false)

        result = processor.send(:find_existing_select_alias, sort)
        expect(result).to be_nil
      end

      it 'returns nil when sort expression is nil' do
        allow(processor).to receive(:extract_sort_expression).and_return(nil)

        result = processor.send(:find_existing_select_alias, sort)
        expect(result).to be_nil
      end
    end

    describe '#matches_select_expression?' do
      it 'matches when select string includes sort expression' do
        result = processor.send(:matches_select_expression?, 'name AS alias', 'name')
        expect(result).to be true
      end

      it 'matches when select string has AS pattern' do
        result = processor.send(:matches_select_expression?, 'users.name AS username', 'users.name')
        expect(result).to be true
      end

      it 'does not match when expressions are different' do
        result = processor.send(:matches_select_expression?, 'email AS email_alias', 'name')
        expect(result).to be false
      end

      it 'handles special characters in sort expression' do
        result = processor.send(:matches_select_expression?, 'COUNT(*) AS count_alias', 'COUNT(*)')
        expect(result).to be true
      end
    end

    describe '#extract_alias_from_select' do
      it 'extracts alias from simple column' do
        result = processor.send(:extract_alias_from_select, 'name AS username')
        expect(result).to eq('username')
      end

      it 'extracts alias from function' do
        result = processor.send(:extract_alias_from_select, 'SUM(hours) AS total_hours')
        expect(result).to eq('total_hours')
      end

      it 'extracts alias from subquery' do
        result = processor.send(:extract_alias_from_select, '(SELECT COUNT(*) FROM users) AS cnt')
        expect(result).to eq('cnt')
      end

      it 'extracts alias from qualified column' do
        result = processor.send(:extract_alias_from_select, 'users.name AS username')
        expect(result).to eq('username')
      end

      it 'returns nil when no alias is present' do
        result = processor.send(:extract_alias_from_select, 'COUNT(*)')
        expect(result).to be_nil
      end

      it 'returns nil for empty string' do
        result = processor.send(:extract_alias_from_select, '')
        expect(result).to be_nil
      end

      it 'handles whitespace around alias' do
        result = processor.send(:extract_alias_from_select, 'name AS  username  ')
        expect(result).to eq('username')
      end
    end

    describe '#add_necessary_selects' do
      let(:processed_sorts) do
        [
          { original_sort: 'name ASC', alias_name: 'alias_123', select_value: Arel.sql('name AS alias_123') },
          { original_sort: 'email DESC', alias_name: 'alias_456', select_value: Arel.sql('email AS alias_456') }
        ]
      end

      context 'when select_values is empty' do
        before { query.select_values = [] }

        it 'adds SELECT * and new selects to the query' do
          processor.send(:add_necessary_selects, processed_sorts)
          expect(query.select_values).to include(Arel.sql("#{query.table.name}.*"))
          expect(query.select_values).to include(Arel.sql('name AS alias_123'))
          expect(query.select_values).to include(Arel.sql('email AS alias_456'))
        end
      end

      context 'when select_values is not empty' do
        before { query.select_values = ['id'] }

        it 'only adds new selects to the query' do
          processor.send(:add_necessary_selects, processed_sorts)
          expect(query.select_values).to include('id')
          expect(query.select_values).to include(Arel.sql('name AS alias_123'))
          expect(query.select_values).to include(Arel.sql('email AS alias_456'))
        end
      end

      context 'when processed_sorts have no select_values' do
        let(:processed_sorts_without_selects) { [{ original_sort: 'name ASC' }] }

        it 'only adds SELECT * if needed' do
          query.select_values = []
          processor.send(:add_necessary_selects, processed_sorts_without_selects)
          expect(query.select_values).to include(Arel.sql("#{query.table.name}.*"))
          expect(query.select_values.length).to eq(1)
        end
      end
    end

    describe '#update_order_values' do
      let(:processed_sorts) do
        [
          { original_sort: 'name ASC', alias_name: 'alias_123' },
          { original_sort: 'email DESC', alias_name: 'alias_456' }
        ]
      end

      it 'updates order_values with aliased column names' do
        processor.send(:update_order_values, processed_sorts)
        expect(query.order_values).to include(Arel.sql('alias_123 ASC'))
        expect(query.order_values).to include(Arel.sql('alias_456 DESC'))
      end
    end

    describe '#build_order_value' do
      context 'when alias_name is present' do
        let(:sort_info) { { original_sort: 'name ASC', alias_name: 'alias_123' } }

        it 'creates a new ORDER BY expression with alias' do
          result = processor.send(:build_order_value, sort_info)
          expect(result).to be_a(Arel::Nodes::SqlLiteral)
          expect(result.to_s).to include('alias_123 ASC')
        end
      end

      context 'when alias_name is not present' do
        let(:sort_info) { { original_sort: 'name ASC' } }

        it 'returns the original sort' do
          result = processor.send(:build_order_value, sort_info)
          expect(result).to eq('name ASC')
        end
      end

      context 'when direction is empty' do
        let(:sort_info) { { original_sort: 'name', alias_name: 'alias_123' } }

        it 'creates ORDER BY expression without direction' do
          result = processor.send(:build_order_value, sort_info)
          expect(result.to_s).to eq('alias_123 ')
        end
      end
    end

    describe '#extract_sort_direction' do
      context 'with Arel ordering node' do
        let(:sort) { Person.arel_table[:name].asc }

        it 'extracts the direction' do
          result = processor.send(:extract_sort_direction, sort)
          expect(result).to eq('ASC')
        end
      end

      context 'with string sort' do
        it 'extracts ASC direction' do
          result = processor.send(:extract_sort_direction, 'name ASC')
          expect(result).to eq('ASC')
        end

        it 'extracts DESC direction' do
          result = processor.send(:extract_sort_direction, 'name DESC')
          expect(result).to eq('DESC')
        end

        it 'extracts direction with NULLS FIRST' do
          result = processor.send(:extract_sort_direction, 'name ASC NULLS FIRST')
          expect(result).to eq('ASC NULLS FIRST')
        end

        it 'extracts direction with NULLS LAST' do
          result = processor.send(:extract_sort_direction, 'name DESC NULLS LAST')
          expect(result).to eq('DESC NULLS LAST')
        end

        it 'returns nil for invalid sort strings' do
          result = processor.send(:extract_sort_direction, 'invalid sort')
          expect(result).to be_nil
        end
      end

      context 'with other types' do
        it 'returns nil' do
          result = processor.send(:extract_sort_direction, 123)
          expect(result).to be_nil
        end
      end
    end

    describe '#extract_order_by_clauses' do
      it 'extracts ORDER BY clauses correctly' do
        expect(processor.send(:extract_order_by_clauses, 'name ASC')).to eq('ASC')
        expect(processor.send(:extract_order_by_clauses, 'name DESC')).to eq('DESC')
        expect(processor.send(:extract_order_by_clauses, 'name ASC NULLS FIRST')).to eq('ASC NULLS FIRST')
        expect(processor.send(:extract_order_by_clauses, 'name DESC NULLS LAST')).to eq('DESC NULLS LAST')
        expect(processor.send(:extract_order_by_clauses, 'name')).to be_nil
      end

      it 'handles case insensitive patterns' do
        expect(processor.send(:extract_order_by_clauses, 'name asc')).to eq('ASC')
        expect(processor.send(:extract_order_by_clauses, 'name desc')).to eq('DESC')
        expect(processor.send(:extract_order_by_clauses, 'name Asc Nulls Last')).to eq('ASC NULLS LAST')
      end
    end

    # Integration tests
    describe 'integration with Search#result' do
      let!(:person1) { Person.create!(name: 'Alice', email: 'alice@example.com') }
      let!(:person2) { Person.create!(name: 'Bob', email: 'bob@example.com') }
      let!(:person3) { Person.create!(name: 'Alice', email: 'alice2@example.com') }

      after { Person.delete_all }

      it 'handles distinct queries with sorting correctly' do
        search = Person.ransack(name_cont: 'Alice')
        result = search.result(distinct: true).order('name ASC, email DESC')

        expect(result.to_sql).to include('DISTINCT')
        expect(result.to_sql).to include('ORDER BY')
        expect { result.to_sql }.not_to raise_error
      end

      it 'works with complex joins and distinct sorting' do
        person1.articles.create!(title: 'Article 1')
        person1.articles.create!(title: 'Article 2')
        person2.articles.create!(title: 'Article 3')

        search = Person.joins(:articles).ransack(name_cont: 'Alice')
        result = search.result(distinct: true).order('people.name ASC, articles.title DESC')

        expect(result.to_sql).to include('DISTINCT')
        expect(result.to_sql).to include('ORDER BY')
        expect { result.to_sql }.not_to raise_error
      end

      it 'handles complex SQL expressions in sorting' do
        search = Person.ransack(name_cont: 'Alice')
        result = search.result(distinct: true).order(Arel.sql('LENGTH(name) ASC, UPPER(email) DESC'))

        expect(result.to_sql).to include('DISTINCT')
        expect(result.to_sql).to include('ORDER BY')
        expect { result.to_sql }.not_to raise_error
      end

      it 'handles subqueries in sorting' do
        search = Person.ransack(name_cont: 'Alice')
        result = search.result(distinct: true).order(Arel.sql('(SELECT COUNT(*) FROM articles WHERE articles.person_id = people.id) DESC'))

        expect(result.to_sql).to include('DISTINCT')
        expect(result.to_sql).to include('ORDER BY')
        expect { result.to_sql }.not_to raise_error
      end
    end
  end
end
