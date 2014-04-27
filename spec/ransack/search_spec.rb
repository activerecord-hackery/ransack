require 'spec_helper'

module Ransack
  describe Search do
    describe '#initialize' do
      it "removes empty conditions before building" do
        Search.any_instance.should_receive(:build).with({})
        Search.new(Person, :name_eq => '')
      end

      it "keeps conditions with a false value before building" do
        Search.any_instance.should_receive(:build).with({"name_eq" => false})
        Search.new(Person, :name_eq => false)
      end

      it "keeps conditions with a value before building" do
        Search.any_instance.should_receive(:build).with({"name_eq" => 'foobar'})
        Search.new(Person, :name_eq => 'foobar')
      end

      it "removes empty suffixed conditions before building" do
        Search.any_instance.should_receive(:build).with({})
        Search.new(Person, :name_eq_any => [''])
      end

      it "keeps suffixed conditions with a false value before building" do
        Search.any_instance.should_receive(:build).with({"name_eq_any" => [false]})
        Search.new(Person, :name_eq_any => [false])
      end

      it "keeps suffixed conditions with a value before building" do
        Search.any_instance.should_receive(:build).with({"name_eq_any" => ['foobar']})
        Search.new(Person, :name_eq_any => ['foobar'])
      end


    end

    describe '#initialize' do
      it 'does not raise exception for string :params argument' do
        lambda { Search.new(Person, '') }.should_not raise_error
      end
    end

    describe '#build' do
      it 'creates conditions for top-level attributes' do
        search = Search.new(Person, name_eq: 'Ernie')
        condition = search.base[:name_eq]
        condition.should be_a Nodes::Condition
        condition.predicate.name.should eq 'eq'
        condition.attributes.first.name.should eq 'name'
        condition.value.should eq 'Ernie'
      end

      it 'creates conditions for association attributes' do
        search = Search.new(Person, children_name_eq: 'Ernie')
        condition = search.base[:children_name_eq]
        condition.should be_a Nodes::Condition
        condition.predicate.name.should eq 'eq'
        condition.attributes.first.name.should eq 'children_name'
        condition.value.should eq 'Ernie'
      end

      it 'creates conditions for polymorphic belongs_to association attributes' do
        search = Search.new(Note, notable_of_Person_type_name_eq: 'Ernie')
        condition = search.base[:notable_of_Person_type_name_eq]
        condition.should be_a Nodes::Condition
        condition.predicate.name.should eq 'eq'
        condition.attributes.first.name.should eq 'notable_of_Person_type_name'
        condition.value.should eq 'Ernie'
      end

      it 'creates conditions for multiple polymorphic belongs_to association attributes' do
        search = Search.new(Note,
          notable_of_Person_type_name_or_notable_of_Article_type_title_eq: 'Ernie')
        condition = search.
          base[:notable_of_Person_type_name_or_notable_of_Article_type_title_eq]
        condition.should be_a Nodes::Condition
        condition.predicate.name.should eq 'eq'
        condition.attributes.first.name.should eq 'notable_of_Person_type_name'
        condition.attributes.last.name.should eq 'notable_of_Article_type_title'
        condition.value.should eq 'Ernie'
      end

      it 'discards empty conditions' do
        search = Search.new(Person, children_name_eq: '')
        condition = search.base[:children_name_eq]
        condition.should be_nil
      end

      it 'accepts arrays of groupings' do
        search = Search.new(Person,
          g: [
            { m: 'or', name_eq: 'Ernie', children_name_eq: 'Ernie' },
            { m: 'or', name_eq: 'Bert',  children_name_eq: 'Bert' },
          ]
        )
        ors = search.groupings
        ors.should have(2).items
        or1, or2 = ors
        or1.should be_a Nodes::Grouping
        or1.combinator.should eq 'or'
        or2.should be_a Nodes::Grouping
        or2.combinator.should eq 'or'
      end

      it 'accepts "attributes" hashes for groupings' do
        search = Search.new(Person,
          g: {
            '0' => { m: 'or', name_eq: 'Ernie', children_name_eq: 'Ernie' },
            '1' => { m: 'or', name_eq: 'Bert',  children_name_eq: 'Bert' },
          }
        )
        ors = search.groupings
        ors.should have(2).items
        or1, or2 = ors
        or1.should be_a Nodes::Grouping
        or1.combinator.should eq 'or'
        or2.should be_a Nodes::Grouping
        or2.combinator.should eq 'or'
      end

      it 'accepts "attributes" hashes for conditions' do
        search = Search.new(Person,
          :c => {
            '0' => { :a => ['name'], :p => 'eq', :v => ['Ernie'] },
            '1' => { :a => ['children_name', 'parent_name'],
                     :p => 'eq', :v => ['Ernie'], :m => 'or' }
            }
        )
        conditions = search.base.conditions
        conditions.should have(2).items
        conditions.map { |c| c.class }
        .should eq [Nodes::Condition, Nodes::Condition]
      end

      it 'creates conditions for custom predicates that take arrays' do
        Ransack.configure do |config|
          config.add_predicate 'ary_pred', :wants_array => true
        end

        search = Search.new(Person, name_ary_pred: ['Ernie', 'Bert'])
        condition = search.base[:name_ary_pred]
        condition.should be_a Nodes::Condition
        condition.predicate.name.should eq 'ary_pred'
        condition.attributes.first.name.should eq 'name'
        condition.value.should eq ['Ernie', 'Bert']
      end

      it 'does not evaluate the query on #inspect' do
        search = Search.new(Person, children_id_in: [1, 2, 3])
        search.inspect.should_not match /ActiveRecord/
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
        search.result.should be_an ActiveRecord::Relation
        where = search.result.where_values.first
        where.to_sql.should match /#{children_people_name_field} = 'Ernie'/
      end

      it 'evaluates compound conditions contextually' do
        search = Search.new(Person, children_name_or_name_eq: 'Ernie')
        search.result.should be_an ActiveRecord::Relation
        where = search.result.where_values.first
        where.to_sql.should match /#{children_people_name_field
          } = 'Ernie' OR #{people_name_field} = 'Ernie'/
      end

      it 'evaluates polymorphic belongs_to association conditions contextually' do
        search = Search.new(Note, notable_of_Person_type_name_eq: 'Ernie')
        search.result.should be_an ActiveRecord::Relation
        where = search.result.where_values.first
        where.to_sql.should match /#{people_name_field} = 'Ernie'/
      end

      it 'evaluates nested conditions' do
        search = Search.new(Person, children_name_eq: 'Ernie',
          g: [
            { m: 'or', name_eq: 'Ernie', children_children_name_eq: 'Ernie' }
          ]
        )
        search.result.should be_an ActiveRecord::Relation
        where = search.result.where_values.first
        where.to_sql.should match /#{children_people_name_field} = 'Ernie'/
        where.to_sql.should match /#{people_name_field} = 'Ernie'/
        where.to_sql.should match /#{quote_table_name("children_people_2")
          }.#{quote_column_name("name")} = 'Ernie'/
      end

      it 'evaluates arrays of groupings' do
        search = Search.new(Person,
          g: [
            { m: 'or', name_eq: 'Ernie', children_name_eq: 'Ernie'},
            { m: 'or', name_eq: 'Bert',  children_name_eq: 'Bert'},
          ]
        )
        search.result.should be_an ActiveRecord::Relation
        where = search.result.where_values.first
        sql = where.to_sql
        first, second = sql.split(/ AND /)
        first.should match /#{people_name_field} = 'Ernie'/
        first.should match /#{children_people_name_field} = 'Ernie'/
        second.should match /#{people_name_field} = 'Bert'/
        second.should match /#{children_people_name_field} = 'Bert'/
      end

      it 'returns distinct records when passed :distinct => true' do
        search = Search.new(
          Person, :g => [
            { :m => 'or',
              :comments_body_cont => 'e',
              :articles_comments_body_cont => 'e'
            }
          ]
        )
        if ActiveRecord::VERSION::MAJOR == 3
          all_or_load, uniq_or_distinct = :all, :uniq
        else
          all_or_load, uniq_or_distinct = :load, :distinct
        end
        search.result.send(all_or_load).
          should have(9000).items
        search.result(:distinct => true).
          should have(10).items
        search.result.send(all_or_load).send(uniq_or_distinct).
          should eq search.result(:distinct => true).send(all_or_load)
      end
    end

    describe '#sorts=' do
      before do
        @s = Search.new(Person)
      end

      it 'creates sorts based on a single attribute/direction' do
        @s.sorts = 'id desc'
        @s.sorts.should have(1).item
        sort = @s.sorts.first
        sort.should be_a Nodes::Sort
        sort.name.should eq 'id'
        sort.dir.should eq 'desc'
      end

      it 'creates sorts based on a single attribute and uppercase direction' do
        @s.sorts = 'id DESC'
        @s.sorts.should have(1).item
        sort = @s.sorts.first
        sort.should be_a Nodes::Sort
        sort.name.should eq 'id'
        sort.dir.should eq 'desc'
      end

      it 'creates sorts based on a single attribute and without direction' do
        @s.sorts = 'id'
        @s.sorts.should have(1).item
        sort = @s.sorts.first
        sort.should be_a Nodes::Sort
        sort.name.should eq 'id'
        sort.dir.should eq 'asc'
      end

      it 'creates sorts based on multiple attributes/directions in array format' do
        @s.sorts = ['id desc', { name: 'name', dir: 'asc' }]
        @s.sorts.should have(2).items
        sort1, sort2 = @s.sorts
        sort1.should be_a Nodes::Sort
        sort1.name.should eq 'id'
        sort1.dir.should eq 'desc'
        sort2.should be_a Nodes::Sort
        sort2.name.should eq 'name'
        sort2.dir.should eq 'asc'
      end

      it 'creates sorts based on multiple attributes and uppercase directions in array format' do
        @s.sorts = ['id DESC', { name: 'name', dir: 'ASC' }]
        @s.sorts.should have(2).items
        sort1, sort2 = @s.sorts
        sort1.should be_a Nodes::Sort
        sort1.name.should eq 'id'
        sort1.dir.should eq 'desc'
        sort2.should be_a Nodes::Sort
        sort2.name.should eq 'name'
        sort2.dir.should eq 'asc'
      end

      it 'creates sorts based on multiple attributes and different directions in array format' do
        @s.sorts = ['id DESC', { name: 'name', dir: nil }]
        @s.sorts.should have(2).items
        sort1, sort2 = @s.sorts
        sort1.should be_a Nodes::Sort
        sort1.name.should eq 'id'
        sort1.dir.should eq 'desc'
        sort2.should be_a Nodes::Sort
        sort2.name.should eq 'name'
        sort2.dir.should eq 'asc'
      end

      it 'creates sorts based on multiple attributes/directions in hash format' do
        @s.sorts = {
          '0' => { name: 'id', dir: 'desc' },
          '1' => { name: 'name', dir: 'asc' }
        }
        @s.sorts.should have(2).items
        @s.sorts.should be_all { |s| Nodes::Sort === s }
        id_sort = @s.sorts.detect { |s| s.name == 'id' }
        name_sort = @s.sorts.detect { |s| s.name == 'name' }
        id_sort.dir.should eq 'desc'
        name_sort.dir.should eq 'asc'
      end

      it 'creates sorts based on multiple attributes and uppercase directions in hash format' do
        @s.sorts = {
            '0' => { name: 'id', dir: 'DESC' },
            '1' => { name: 'name', dir: 'ASC' }
        }
        @s.sorts.should have(2).items
        @s.sorts.should be_all { |s| Nodes::Sort === s }
        id_sort = @s.sorts.detect { |s| s.name == 'id' }
        name_sort = @s.sorts.detect { |s| s.name == 'name' }
        id_sort.dir.should eq 'desc'
        name_sort.dir.should eq 'asc'
      end

      it 'creates sorts based on multiple attributes and different directions in hash format' do
        @s.sorts = {
            '0' => { name: 'id', dir: 'DESC' },
            '1' => { name: 'name', dir: nil }
        }
        @s.sorts.should have(2).items
        @s.sorts.should be_all { |s| Nodes::Sort === s }
        id_sort = @s.sorts.detect { |s| s.name == 'id' }
        name_sort = @s.sorts.detect { |s| s.name == 'name' }
        id_sort.dir.should eq 'desc'
        name_sort.dir.should eq 'asc'
      end

      it 'overrides existing sort' do
        @s.sorts = 'id asc'
        @s.result.first.id.should eq 1
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
        @s.name_eq.should eq 'Ernie'
      end

      it 'allows chaining to access nested conditions' do
        @s.groupings = [
          { m: 'or', name_eq: 'Ernie', children_name_eq: 'Ernie' }
        ]
        @s.groupings.first.children_name_eq.should eq 'Ernie'
      end
    end
  end
end
