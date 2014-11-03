require 'mongoid_spec_helper'

module Ransack
  describe Predicate do

    before do
      @s = Search.new(Person)
    end

    shared_examples 'wildcard escaping' do |method, value|
      it 'automatically converts integers to strings' do
        subject.parent_id_cont = 1
        expect { subject.result }.to_not raise_error
      end

      it "escapes '%', '.' and '\\\\' in value" do
        subject.send(:"#{method}=", '%._\\')
        expect(subject.result.selector).to eq(value)
      end
    end

    describe 'eq' do
      it 'generates an equality condition for boolean true' do
        @s.awesome_eq = true
        expect(@s.result.selector).to eq({ "awesome" => true })
      end

      it 'generates an equality condition for boolean false' do
        @s.awesome_eq = false
        expect(@s.result.selector).to eq({ "awesome" => false })
      end

      it 'does not generate a condition for nil' do
        @s.awesome_eq = nil
        expect(@s.result.selector).to eq({ })
      end
    end

    describe 'cont' do
      it_has_behavior 'wildcard escaping', :name_cont, { 'name' => /%\._\\/i } do
        subject { @s }
      end

      it 'generates a regex query' do
        @s.name_cont = 'ric'
        expect(@s.result.selector).to eq({ 'name' => /ric/i })
      end
    end

    describe 'not_cont' do
      it_has_behavior 'wildcard escaping', :name_not_cont, { "$not" => { 'name' => /%\._\\/i } } do
        subject { @s }
      end

      it 'generates a regex query' do
        @s.name_not_cont = 'ric'
        expect(@s.result.selector).to eq({ "$not" => { 'name' => /ric/i } })
      end
    end

    describe 'null' do
      it 'generates a value IS NULL query' do
        @s.name_null = true
        expect(@s.result.selector).to eq({ 'name' => nil })
      end

      it 'generates a value IS NOT NULL query when assigned false' do
        @s.name_null = false
        expect(@s.result.selector).to eq( { 'name' => { '$ne' => nil } })
      end
    end

    describe 'not_null' do
      it 'generates a value IS NOT NULL query' do
        @s.name_not_null = true
        expect(@s.result.selector).to eq({ 'name' => { '$ne' => nil } })
      end

      it 'generates a value IS NULL query when assigned false' do
        @s.name_not_null = false
        expect(@s.result.selector).to eq({ 'name' => nil })
      end
    end

    describe 'present' do
      it %q[generates a value IS NOT NULL AND value != '' query] do
        @s.name_present = true
        expect(@s.result.selector).to eq({ '$and' => [ { 'name' => { '$ne' => nil } }, { 'name' => { '$ne' => '' } } ] })
      end

      it %q[generates a value IS NULL OR value = '' query when assigned false] do
        @s.name_present = false
        expect(@s.result.selector).to eq({ '$or' => [ { 'name' => nil }, { 'name' => '' } ] })
      end
    end

    describe 'blank' do
      it %q[generates a value IS NULL OR value = '' query] do
        @s.name_blank = true
        expect(@s.result.selector).to eq({ '$or' => [ { 'name' => nil}, { 'name' => '' } ] })
      end

      it %q[generates a value IS NOT NULL AND value != '' query when assigned false] do
        @s.name_blank = false
        expect(@s.result.selector).to eq({ '$and' => [ { 'name' => { '$ne' => nil}}, { 'name' => { '$ne' => '' }} ] })
      end
    end

    describe 'gt' do
      it 'generates an greater than for time' do
        time = Time.now
        @s.created_at_gt = time
        expect(@s.result.selector).to eq({ "created_at" => { '$gt' => time } })
      end
    end

    describe 'lt' do
      it 'generates an greater than for time' do
        time = Time.now
        @s.created_at_lt = time
        expect(@s.result.selector).to eq({ "created_at" => { '$lt' => time } })
      end
    end

    describe 'gteq' do
      it 'generates an greater than for time' do
        time = Time.now
        @s.created_at_gteq = time
        expect(@s.result.selector).to eq({ "created_at" => { '$gte' => time } })
      end
    end

    describe 'lteq' do
      it 'generates an greater than for time' do
        time = Time.now
        @s.created_at_lteq = time
        expect(@s.result.selector).to eq({ "created_at" => { '$lte' => time } })
      end
    end

    describe 'starts_with' do
      it 'generates an starts_with' do
        @s.name_start = 'ric'
        expect(@s.result.selector).to eq({ "name" => /\Aric/i })
      end
    end

    describe 'ends_with' do
      it 'generates an ends_with' do
        @s.name_end = 'ric'
        expect(@s.result.selector).to eq({ "name" => /ric\Z/i })
      end
    end
  end
end
