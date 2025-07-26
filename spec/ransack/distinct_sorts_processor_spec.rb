require 'spec_helper'

module Ransack
  describe DistinctSortsProcessor do
    let(:search) { Search.new(Person) }
    let(:query) { Person.ransack.result }
    let(:sorts) { [] }
    let(:processor) { DistinctSortsProcessor.new(search, query, sorts) }

    # Mock SecureRandom to return predictable values for testing
    before do
      allow(SecureRandom).to receive(:hex).with(10).and_return('abc123')
    end

    # Helper method to create a query with distinct
    def create_distinct_query
      Person.ransack.result(distinct: true)
    end

    describe '.should_process?' do
      context 'when query has distinct and sorts' do
        let(:query) { Person.ransack.result(distinct: true) }
        let(:sorts) { ['name ASC'] }

        it 'returns true' do
          expect(DistinctSortsProcessor.should_process?(query, sorts)).to be true
        end
      end

      context 'when query has distinct but no sorts' do
        let(:query) { Person.ransack.result(distinct: true) }
        let(:sorts) { [] }

        it 'returns false' do
          expect(DistinctSortsProcessor.should_process?(query, sorts)).to be false
        end
      end

      context 'when query has sorts but no distinct' do
        let(:query) { Person.ransack.result }
        let(:sorts) { ['name ASC'] }

        it 'returns false' do
          result = DistinctSortsProcessor.should_process?(query, sorts)
          expect(result).to eq(false)
        end
      end

      context 'when query has neither distinct nor sorts' do
        let(:query) { Person.ransack.result }
        let(:sorts) { [] }

        it 'returns false' do
          result = DistinctSortsProcessor.should_process?(query, sorts)
          expect(result).to eq(false)
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
      let(:query) { Person.ransack.result(distinct: true) }
      let(:sorts) { ['name ASC', 'created_at DESC'] }

      before do
        allow(processor).to receive(:build_select_sorts).and_return([
          {
            sort: 'name ASC',
            select: Arel.sql('name AS alias_123'),
            alias_name: 'alias_123'
          },
          {
            sort: 'created_at DESC',
            select: Arel.sql('created_at AS alias_456'),
            alias_name: 'alias_456'
          }
        ])
      end

      it 'calls all required processing methods' do
        expect(processor).to receive(:add_default_select_if_needed)
        expect(processor).to receive(:add_sort_selects)
        expect(processor).to receive(:update_order_values)

        processor.process!
      end

      it 'modifies the query in place' do
        original_select_values = query.select_values.dup
        original_order_values = query.order_values.dup

        processor.process!

        expect(query.select_values).not_to eq(original_select_values)
        expect(query.order_values).not_to eq(original_order_values)
      end
    end

    describe '#build_select_sorts' do
      let(:sorts) { ['name ASC', 'created_at DESC'] }

      it 'returns an array of select sort objects' do
        result = processor.send(:build_select_sorts)
        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
        expect(result.first).to include(:sort, :select, :alias_name)
      end

      it 'filters out nil results' do
        allow(processor).to receive(:build_select_sort).and_return(nil, { sort: 'test', select: 'test', alias_name: 'test' })
        result = processor.send(:build_select_sorts)
        expect(result.length).to eq(1)
      end
    end

    describe '#build_select_sort' do
      let(:alias_name) { 'alias_123' }

      context 'with Arel ordering node' do
        let(:sort) { Person.arel_table[:name].asc }

        it 'creates a select sort object for valid Arel attributes when not using SELECT *' do
          # Mock the query to have explicit selects
          allow(search.instance_variable_get(:@context).evaluate(search)).to receive(:select_values).and_return(['id'])

          result = processor.send(:build_select_sort, sort)
          expect(result).to include(:sort, :select, :alias_name)
          expect(result[:sort]).to eq(sort)
          expect(result[:alias_name]).to eq('alias_abc123')
        end

        it 'returns nil for columns that should be skipped (using SELECT *)' do
          # Mock the query to use SELECT *
          allow(search.instance_variable_get(:@context).evaluate(search)).to receive(:select_values).and_return([])
          allow(search.klass).to receive(:column_names).and_return(['name', 'email'])
          allow(search.klass).to receive(:table_name).and_return('people')

          result = processor.send(:build_select_sort, sort)
          expect(result).to be_nil
        end

        it 'returns nil for non-Arel attributes' do
          non_attribute_sort = Arel.sql('COUNT(*)').asc
          result = processor.send(:build_select_sort, non_attribute_sort)
          expect(result).to be_nil
        end
      end

      context 'with string sort' do
        let(:sort) { 'name ASC' }

        it 'creates a select sort object' do
          result = processor.send(:build_select_sort, sort)
          expect(result).to include(:sort, :select, :alias_name)
          expect(result[:sort]).to eq(sort)
          expect(result[:alias_name]).to eq('alias_abc123')
        end

        it 'handles complex sort strings with NULLS' do
          complex_sort = 'name ASC NULLS LAST'
          result = processor.send(:build_select_sort, complex_sort)
          expect(result[:select]).to be_a(Arel::Nodes::SqlLiteral)
        end
      end

      context 'with other types' do
        it 'returns nil for unsupported types' do
          result = processor.send(:build_select_sort, 123)
          expect(result).to be_nil
        end
      end
    end

    describe '#generate_alias_name' do
      it 'generates unique alias names' do
        # Reset the mock to return different values
        allow(SecureRandom).to receive(:hex).with(10).and_return('abc123', 'def456')

        alias1 = processor.send(:generate_alias_name)
        alias2 = processor.send(:generate_alias_name)

        expect(alias1).to start_with('alias_')
        expect(alias2).to start_with('alias_')
        expect(alias1).not_to eq(alias2)
      end

      it 'uses SecureRandom for uniqueness' do
        expect(SecureRandom).to receive(:hex).with(10).and_return('abc123')
        alias_name = processor.send(:generate_alias_name)
        expect(alias_name).to eq('alias_abc123')
      end
    end

    describe '#extract_select_value' do
      let(:alias_name) { 'alias_123' }

      context 'with Arel ordering node' do
        let(:sort) { Person.arel_table[:name].asc }

        it 'calls extract_ordering_select_value' do
          expect(processor).to receive(:extract_ordering_select_value).with(sort, alias_name)
          processor.send(:extract_select_value, sort, alias_name)
        end
      end

      context 'with string sort' do
        let(:sort) { 'name ASC' }

        it 'calls extract_string_select_value' do
          expect(processor).to receive(:extract_string_select_value).with(sort, alias_name)
          processor.send(:extract_select_value, sort, alias_name)
        end
      end

      context 'with other types' do
        it 'returns nil' do
          result = processor.send(:extract_select_value, 123, alias_name)
          expect(result).to be_nil
        end
      end
    end

    describe '#extract_ordering_select_value' do
      let(:alias_name) { 'alias_123' }

      context 'with Arel attribute' do
        let(:sort) { Person.arel_table[:name].asc }

        it 'creates an aliased column when not skipped' do
          allow(processor).to receive(:should_skip_column?).and_return(false)
          result = processor.send(:extract_ordering_select_value, sort, alias_name)
          expect(result).to be_a(Arel::Nodes::As)
        end

        it 'skips columns that should be skipped' do
          allow(processor).to receive(:should_skip_column?).and_return(true)
          result = processor.send(:extract_ordering_select_value, sort, alias_name)
          expect(result).to be_nil
        end
      end

      context 'with non-Arel attribute' do
        let(:sort) { Arel.sql('COUNT(*)').asc }

        it 'returns nil' do
          result = processor.send(:extract_ordering_select_value, sort, alias_name)
          expect(result).to be_nil
        end
      end
    end

    describe '#extract_string_select_value' do
      let(:alias_name) { 'alias_123' }

      it 'removes ORDER BY clauses and adds alias' do
        sort = 'name ASC'
        result = processor.send(:extract_string_select_value, sort, alias_name)
        expect(result).to be_a(Arel::Nodes::SqlLiteral)
        expect(result.to_s).to include('name AS alias_123')
      end

      it 'handles complex sort strings with NULLS' do
        sort = 'name ASC NULLS LAST'
        result = processor.send(:extract_string_select_value, sort, alias_name)
        expect(result.to_s).to include('name AS alias_123')
        expect(result.to_s).not_to include('ASC NULLS LAST')
      end

      it 'handles DESC with NULLS' do
        sort = 'created_at DESC NULLS FIRST'
        result = processor.send(:extract_string_select_value, sort, alias_name)
        expect(result.to_s).to include('created_at AS alias_123')
        expect(result.to_s).not_to include('DESC NULLS FIRST')
      end
    end

    describe '#should_skip_column?' do
      let(:column_name) { 'name' }
      let(:relation_name) { 'people' }

      context 'when using SELECT * and column exists in model' do
        before do
          allow(search.instance_variable_get(:@context).evaluate(search)).to receive(:select_values).and_return([])
          allow(search.klass).to receive(:column_names).and_return(['name', 'email'])
          allow(search.klass).to receive(:table_name).and_return('people')
        end

        it 'returns true' do
          result = processor.send(:should_skip_column?, column_name, relation_name)
          expect(result).to be true
        end
      end

      context 'when not using SELECT *' do
        before do
          allow(search.instance_variable_get(:@context).evaluate(search)).to receive(:select_values).and_return(['id'])
        end

        it 'returns false' do
          result = processor.send(:should_skip_column?, column_name, relation_name)
          expect(result).to be false
        end
      end

      context 'when column does not exist in model' do
        before do
          allow(search.instance_variable_get(:@context).evaluate(search)).to receive(:select_values).and_return([])
          allow(search.klass).to receive(:column_names).and_return(['email'])
          allow(search.klass).to receive(:table_name).and_return('people')
        end

        it 'returns false' do
          result = processor.send(:should_skip_column?, column_name, relation_name)
          expect(result).to be false
        end
      end

      context 'when relation name does not match table name' do
        before do
          allow(search.instance_variable_get(:@context).evaluate(search)).to receive(:select_values).and_return([])
          allow(search.klass).to receive(:column_names).and_return(['name'])
          allow(search.klass).to receive(:table_name).and_return('users')
        end

        it 'returns false' do
          result = processor.send(:should_skip_column?, column_name, relation_name)
          expect(result).to be false
        end
      end
    end

    describe '#add_default_select_if_needed' do
      context 'when select_values is empty' do
        before do
          query.select_values = []
        end

        it 'adds SELECT * to the query' do
          processor.send(:add_default_select_if_needed)
          expect(query.select_values).to include(Arel.sql("#{query.table.name}.*"))
        end
      end

      context 'when select_values is not empty' do
        before do
          query.select_values = ['id']
        end

        it 'does not add SELECT *' do
          original_select_values = query.select_values.dup
          processor.send(:add_default_select_if_needed)
          expect(query.select_values).to eq(original_select_values)
        end
      end
    end

    describe '#add_sort_selects' do
      let(:select_sorts) do
        [
          { select: Arel.sql('name AS alias_123') },
          { select: Arel.sql('created_at AS alias_456') }
        ]
      end

      it 'adds select values to the query' do
        original_select_values = query.select_values.dup
        processor.send(:add_sort_selects, select_sorts)
        expect(query.select_values.length).to eq(original_select_values.length + 2)
      end
    end

    describe '#update_order_values' do
      let(:select_sorts) do
        [
          { sort: 'name ASC', alias_name: 'alias_123' },
          { sort: 'created_at DESC', alias_name: 'alias_456' }
        ]
      end

      it 'updates order_values with aliased column names' do
        processor.send(:update_order_values, select_sorts)
        expect(query.order_values).to include(Arel.sql('alias_123 ASC'))
        expect(query.order_values).to include(Arel.sql('alias_456 DESC'))
      end
    end

    describe '#build_new_order_value' do
      let(:sort_info) do
        {
          sort: 'name ASC',
          alias_name: 'alias_123'
        }
      end

      it 'creates a new ORDER BY expression with alias' do
        result = processor.send(:build_new_order_value, sort_info)
        expect(result).to be_a(Arel::Nodes::SqlLiteral)
        expect(result.to_s).to include('alias_123 ASC')
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

    # Integration tests
    describe 'integration with Search#result' do
      let!(:person1) { Person.create!(name: 'Alice', email: 'alice@example.com') }
      let!(:person2) { Person.create!(name: 'Bob', email: 'bob@example.com') }
      let!(:person3) { Person.create!(name: 'Alice', email: 'alice2@example.com') }

      after do
        Person.delete_all
      end

      it 'handles distinct queries with sorting correctly' do
        search = Person.ransack(name_cont: 'Alice')
        result = search.result(distinct: true).order('name ASC, email DESC')

        expect(result.to_sql).to include('DISTINCT')
        expect(result.to_sql).to include('ORDER BY')
        # Test that the processor is called and doesn't raise errors
        expect { result.to_sql }.not_to raise_error
      end

      it 'works with complex joins and distinct sorting' do
        # Create some articles for the people
        person1.articles.create!(title: 'Article 1')
        person1.articles.create!(title: 'Article 2')
        person2.articles.create!(title: 'Article 3')

        search = Person.joins(:articles).ransack(name_cont: 'Alice')
        result = search.result(distinct: true).order('people.name ASC, articles.title DESC')

        expect(result.to_sql).to include('DISTINCT')
        expect(result.to_sql).to include('ORDER BY')
        # Test that the processor is called and doesn't raise errors
        expect { result.to_sql }.not_to raise_error
      end
    end
  end
end
