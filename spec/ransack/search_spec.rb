require 'spec_helper'

module Ransack
  describe Search do
    describe '#initialize' do
      it 'removes empty conditions before building' do
        expect_any_instance_of(Search).to receive(:build).with({})
        Search.new(Person, name_eq: '')
      end

      it 'keeps conditions with a false value before building' do
        expect_any_instance_of(Search).to receive(:build)
        .with({ 'name_eq' => false })
        Search.new(Person, name_eq: false)
      end

      it 'keeps conditions with a value before building' do
        expect_any_instance_of(Search).to receive(:build)
        .with({ 'name_eq' => 'foobar' })
        Search.new(Person, name_eq: 'foobar')
      end

      it 'removes empty suffixed conditions before building' do
        expect_any_instance_of(Search).to receive(:build).with({})
        Search.new(Person, name_eq_any: [''])
      end

      it 'keeps suffixed conditions with a false value before building' do
        expect_any_instance_of(Search).to receive(:build)
        .with({ 'name_eq_any' => [false] })
        Search.new(Person, name_eq_any: [false])
      end

      it 'keeps suffixed conditions with a value before building' do
        expect_any_instance_of(Search).to receive(:build)
        .with({ 'name_eq_any' => ['foobar'] })
        Search.new(Person, name_eq_any: ['foobar'])
      end

      it 'does not raise exception for string :params argument' do
        expect { Search.new(Person, '') }.not_to raise_error
      end

      it 'accepts a context option' do
        shared_context = Context.for(Person)
        search1 = Search.new(Person, { name_eq: 'A' }, context: shared_context)
        search2 = Search.new(Person, { name_eq: 'B' }, context: shared_context)
        expect(search1.context).to be search2.context
      end
    end

    describe '#build' do
      it 'creates conditions for top-level attributes' do
        search = Search.new(Person, name_eq: 'Ernie')
        condition = search.base[:name_eq]
        expect(condition).to be_a Nodes::Condition
        expect(condition.predicate.name).to eq 'eq'
        expect(condition.attributes.first.name).to eq 'name'
        expect(condition.value).to eq 'Ernie'
      end

      it 'creates conditions for association attributes' do
        search = Search.new(Person, children_name_eq: 'Ernie')
        condition = search.base[:children_name_eq]
        expect(condition).to be_a Nodes::Condition
        expect(condition.predicate.name).to eq 'eq'
        expect(condition.attributes.first.name).to eq 'children_name'
        expect(condition.value).to eq 'Ernie'
      end

      it 'creates conditions for polymorphic belongs_to association attributes' do
        search = Search.new(Note, notable_of_Person_type_name_eq: 'Ernie')
        condition = search.base[:notable_of_Person_type_name_eq]
        expect(condition).to be_a Nodes::Condition
        expect(condition.predicate.name).to eq 'eq'
        expect(condition.attributes.first.name)
          .to eq 'notable_of_Person_type_name'
        expect(condition.value).to eq 'Ernie'
      end

      it 'creates conditions for multiple polymorphic belongs_to association
        attributes' do
        search = Search.new(Note,
          notable_of_Person_type_name_or_notable_of_Article_type_title_eq: 'Ernie')
        condition = search.
          base[:notable_of_Person_type_name_or_notable_of_Article_type_title_eq]
        expect(condition).to be_a Nodes::Condition
        expect(condition.predicate.name).to eq 'eq'
        expect(condition.attributes.first.name)
          .to eq 'notable_of_Person_type_name'
        expect(condition.attributes.last.name)
          .to eq 'notable_of_Article_type_title'
        expect(condition.value).to eq 'Ernie'
      end

      it 'preserves default scope and conditions for associations' do
        search = Search.new(Person, published_articles_title_eq: 'Test')
        expect(search.result.to_sql).to include 'default_scope'
        expect(search.result.to_sql).to include 'published'
      end

      it 'discards empty conditions' do
        search = Search.new(Person, children_name_eq: '')
        condition = search.base[:children_name_eq]
        expect(condition).to be_nil
      end

      it 'accepts base grouping condition as an option' do
        expect(Nodes::Grouping).to receive(:new).with(kind_of(Context), 'or')
        Search.new(Person, {}, { grouping: 'or' })
      end

      it 'accepts arrays of groupings' do
        search = Search.new(Person,
          g: [
            { m: 'or', name_eq: 'Ernie', children_name_eq: 'Ernie' },
            { m: 'or', name_eq: 'Bert', children_name_eq: 'Bert' },
          ]
        )
        ors = search.groupings
        expect(ors.size).to eq(2)
        or1, or2 = ors
        expect(or1).to be_a Nodes::Grouping
        expect(or1.combinator).to eq 'or'
        expect(or2).to be_a Nodes::Grouping
        expect(or2.combinator).to eq 'or'
      end

      it 'accepts "attributes" hashes for groupings' do
        search = Search.new(Person,
          g: {
            '0' => { m: 'or', name_eq: 'Ernie', children_name_eq: 'Ernie' },
            '1' => { m: 'or', name_eq: 'Bert',  children_name_eq: 'Bert' },
          }
        )
        ors = search.groupings
        expect(ors.size).to eq(2)
        or1, or2 = ors
        expect(or1).to be_a Nodes::Grouping
        expect(or1.combinator).to eq 'or'
        expect(or2).to be_a Nodes::Grouping
        expect(or2.combinator).to eq 'or'
      end

      it 'accepts "attributes" hashes for conditions' do
        search = Search.new(Person,
          c: {
            '0' => { a: ['name'], p: 'eq', v: ['Ernie'] },
            '1' => {
                     a: ['children_name', 'parent_name'],
                     p: 'eq', v: ['Ernie'], m: 'or'
                   }
          }
        )
        conditions = search.base.conditions
        expect(conditions.size).to eq(2)
        expect(conditions.map { |c| c.class })
        .to eq [Nodes::Condition, Nodes::Condition]
      end

      it 'creates conditions for custom predicates that take arrays' do
        Ransack.configure do |config|
          config.add_predicate 'ary_pred', wants_array: true
        end

        search = Search.new(Person, name_ary_pred: ['Ernie', 'Bert'])
        condition = search.base[:name_ary_pred]
        expect(condition).to be_a Nodes::Condition
        expect(condition.predicate.name).to eq 'ary_pred'
        expect(condition.attributes.first.name).to eq 'name'
        expect(condition.value).to eq ['Ernie', 'Bert']
      end

      it 'does not evaluate the query on #inspect' do
        search = Search.new(Person, children_id_in: [1, 2, 3])
        expect(search.inspect).not_to match /ActiveRecord/
      end

      context 'with an invalid condition' do
        subject { Search.new(Person, unknown_attr_eq: 'Ernie') }

        context 'when ignore_unknown_conditions is false' do
          before do
            Ransack.configure { |c| c.ignore_unknown_conditions = false }
          end

          specify { expect { subject }.to raise_error ArgumentError }
        end

        context 'when ignore_unknown_conditions is true' do
          before do
            Ransack.configure { |c| c.ignore_unknown_conditions = true }
          end

          specify { expect { subject }.not_to raise_error }
        end
      end

      it 'does not modify the parameters' do
        params = { name_eq: '' }
        expect { Search.new(Person, params) }.not_to change { params }
      end

    end

    describe '#result' do
      let(:people_name_field) {
        "#{quote_table_name("people")}.#{quote_column_name("name")}"
      }
      let(:children_people_name_field) {
        "#{quote_table_name("children_people")}.#{quote_column_name("name")}"
      }
      it 'evaluates conditions contextually' do
        search = Search.new(Person, children_name_eq: 'Ernie')
        expect(search.result).to be_an ActiveRecord::Relation
        expect(search.result.to_sql).to match /#{
          children_people_name_field} = 'Ernie'/
      end

      # FIXME: Make this spec pass for Rails 4.1 / 4.2 / 5.0 and not just 4.0 by
      # commenting out lines 221 and 242 to run the test. Addresses issue #374.
      # https://github.com/activerecord-hackery/ransack/issues/374
      #
      if ::ActiveRecord::VERSION::STRING.first(3) == '4.0'
        it 'evaluates conditions for multiple belongs_to associations to the
        same table contextually' do
          s = Search.new(Recommendation,
            person_name_eq: 'Ernie',
            target_person_parent_name_eq: 'Test'
          ).result
          expect(s).to be_an ActiveRecord::Relation
          real_query = remove_quotes_and_backticks(s.to_sql)
          expected_query = <<-SQL
            SELECT recommendations.* FROM recommendations
            LEFT OUTER JOIN people ON people.id = recommendations.person_id
            LEFT OUTER JOIN people target_people_recommendations
              ON target_people_recommendations.id = recommendations.target_person_id
            LEFT OUTER JOIN people parents_people
              ON parents_people.id = target_people_recommendations.parent_id
            WHERE ((people.name = 'Ernie' AND parents_people.name = 'Test'))
          SQL
          .squish
          expect(real_query).to eq expected_query
        end
      end

      it 'evaluates compound conditions contextually' do
        search = Search.new(Person, children_name_or_name_eq: 'Ernie').result
        expect(search).to be_an ActiveRecord::Relation
        expect(search.to_sql).to match /#{children_people_name_field
          } = 'Ernie' OR #{people_name_field} = 'Ernie'/
      end

      it 'evaluates polymorphic belongs_to association conditions contextually' do
        search = Search.new(Note, notable_of_Person_type_name_eq: 'Ernie')
        .result
        expect(search).to be_an ActiveRecord::Relation
        expect(search.to_sql).to match /#{people_name_field} = 'Ernie'/
      end

      it 'evaluates nested conditions' do
        search = Search.new(Person, children_name_eq: 'Ernie',
          g: [
            { m: 'or', name_eq: 'Ernie', children_children_name_eq: 'Ernie' }
          ]
        ).result
        expect(search).to be_an ActiveRecord::Relation
        first, last = search.to_sql.split(/ AND /)
        expect(first).to match /#{children_people_name_field} = 'Ernie'/
        expect(last).to match /#{
          people_name_field} = 'Ernie' OR #{
          quote_table_name("children_people_2")}.#{
          quote_column_name("name")} = 'Ernie'/
      end

      it 'evaluates arrays of groupings' do
        search = Search.new(Person,
          g: [
            { m: 'or', name_eq: 'Ernie', children_name_eq: 'Ernie' },
            { m: 'or', name_eq: 'Bert', children_name_eq: 'Bert' }
          ]
        ).result
        expect(search).to be_an ActiveRecord::Relation
        first, last = search.to_sql.split(/ AND /)
        expect(first).to match /#{people_name_field} = 'Ernie' OR #{
          children_people_name_field} = 'Ernie'/
        expect(last).to match /#{people_name_field} = 'Bert' OR #{
          children_people_name_field} = 'Bert'/
      end

      it 'returns distinct records when passed distinct: true' do
        search = Search.new(Person,
          g: [
            { m: 'or', comments_body_cont: 'e', articles_comments_body_cont: 'e' }
          ]
        )
        if ActiveRecord::VERSION::MAJOR == 3
          all_or_load, uniq_or_distinct = :all, :uniq
        else
          all_or_load, uniq_or_distinct = :load, :distinct
        end
        expect(search.result.send(all_or_load).size)
        .to eq(9000)
        expect(search.result(distinct: true).size)
        .to eq(10)
        expect(search.result.send(all_or_load).send(uniq_or_distinct))
        .to eq search.result(distinct: true).send(all_or_load)
      end

      private

        def remove_quotes_and_backticks(str)
          str.gsub(/["`]/, '')
        end
    end

    describe '#sorts=' do
      before do
        @s = Search.new(Person)
      end

      it 'creates sorts based on a single attribute/direction' do
        @s.sorts = 'id desc'
        expect(@s.sorts.size).to eq(1)
        sort = @s.sorts.first
        expect(sort).to be_a Nodes::Sort
        expect(sort.name).to eq 'id'
        expect(sort.dir).to eq 'desc'
      end

      it 'creates sorts based on a single attribute and uppercase direction' do
        @s.sorts = 'id DESC'
        expect(@s.sorts.size).to eq(1)
        sort = @s.sorts.first
        expect(sort).to be_a Nodes::Sort
        expect(sort.name).to eq 'id'
        expect(sort.dir).to eq 'desc'
      end

      it 'creates sorts based on a single attribute and without direction' do
        @s.sorts = 'id'
        expect(@s.sorts.size).to eq(1)
        sort = @s.sorts.first
        expect(sort).to be_a Nodes::Sort
        expect(sort.name).to eq 'id'
        expect(sort.dir).to eq 'asc'
      end

      it 'creates sorts based on multiple attributes/directions in array format' do
        @s.sorts = ['id desc', { name: 'name', dir: 'asc' }]
        expect(@s.sorts.size).to eq(2)
        sort1, sort2 = @s.sorts
        expect(sort1).to be_a Nodes::Sort
        expect(sort1.name).to eq 'id'
        expect(sort1.dir).to eq 'desc'
        expect(sort2).to be_a Nodes::Sort
        expect(sort2.name).to eq 'name'
        expect(sort2.dir).to eq 'asc'
      end

      it 'creates sorts based on multiple attributes and uppercase directions in array format' do
        @s.sorts = ['id DESC', { name: 'name', dir: 'ASC' }]
        expect(@s.sorts.size).to eq(2)
        sort1, sort2 = @s.sorts
        expect(sort1).to be_a Nodes::Sort
        expect(sort1.name).to eq 'id'
        expect(sort1.dir).to eq 'desc'
        expect(sort2).to be_a Nodes::Sort
        expect(sort2.name).to eq 'name'
        expect(sort2.dir).to eq 'asc'
      end

      it 'creates sorts based on multiple attributes and different directions
        in array format' do
        @s.sorts = ['id DESC', { name: 'name', dir: nil }]
        expect(@s.sorts.size).to eq(2)
        sort1, sort2 = @s.sorts
        expect(sort1).to be_a Nodes::Sort
        expect(sort1.name).to eq 'id'
        expect(sort1.dir).to eq 'desc'
        expect(sort2).to be_a Nodes::Sort
        expect(sort2.name).to eq 'name'
        expect(sort2.dir).to eq 'asc'
      end

      it 'creates sorts based on multiple attributes/directions in hash format' do
        @s.sorts = {
          '0' => { name: 'id', dir: 'desc' },
          '1' => { name: 'name', dir: 'asc' }
        }
        expect(@s.sorts.size).to eq(2)
        expect(@s.sorts).to be_all { |s| Nodes::Sort === s }
        id_sort = @s.sorts.detect { |s| s.name == 'id' }
        name_sort = @s.sorts.detect { |s| s.name == 'name' }
        expect(id_sort.dir).to eq 'desc'
        expect(name_sort.dir).to eq 'asc'
      end

      it 'creates sorts based on multiple attributes and uppercase directions
        in hash format' do
        @s.sorts = {
          '0' => { name: 'id', dir: 'DESC' },
          '1' => { name: 'name', dir: 'ASC' }
        }
        expect(@s.sorts.size).to eq(2)
        expect(@s.sorts).to be_all { |s| Nodes::Sort === s }
        id_sort = @s.sorts.detect { |s| s.name == 'id' }
        name_sort = @s.sorts.detect { |s| s.name == 'name' }
        expect(id_sort.dir).to eq 'desc'
        expect(name_sort.dir).to eq 'asc'
      end

      it 'creates sorts based on multiple attributes and different directions
        in hash format' do
        @s.sorts = {
          '0' => { name: 'id', dir: 'DESC' },
          '1' => { name: 'name', dir: nil }
        }
        expect(@s.sorts.size).to eq(2)
        expect(@s.sorts).to be_all { |s| Nodes::Sort === s }
        id_sort = @s.sorts.detect { |s| s.name == 'id' }
        name_sort = @s.sorts.detect { |s| s.name == 'name' }
        expect(id_sort.dir).to eq 'desc'
        expect(name_sort.dir).to eq 'asc'
      end

      it 'overrides existing sort' do
        @s.sorts = 'id asc'
        expect(@s.result.first.id).to eq 1
      end
    end

    describe '#method_missing' do
      before do
        @s = Search.new(Person)
      end

      it 'raises NoMethodError when sent an invalid attribute' do
        expect { @s.blah }.to raise_error NoMethodError
      end

      it 'sets condition attributes when sent valid attributes' do
        @s.name_eq = 'Ernie'
        expect(@s.name_eq).to eq 'Ernie'
      end

      it 'allows chaining to access nested conditions' do
        @s.groupings = [
          { m: 'or', name_eq: 'Ernie', children_name_eq: 'Ernie' }
        ]
        expect(@s.groupings.first.children_name_eq).to eq 'Ernie'
      end
    end
  end
end
