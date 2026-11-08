require 'spec_helper'

module Ransack
  # Search params usually come from the query string, where anyone can write
  # `q[g]=x`. Params of the wrong shape raise InvalidSearchError, the error an
  # application rescues to answer a bad search with a 400, from a lenient
  # search as well as a strict one. Before, they raised ArgumentError,
  # NoMethodError or TypeError from wherever the shape first broke.
  describe 'malformed search params' do
    def name_column
      conn = Person.connection
      "#{conn.quote_table_name('people')}.#{conn.quote_column_name('name')}"
    end

    def params(query)
      Rack::Utils.parse_nested_query(query)['q']
    end

    shapes = {
      'a grouping that is a string'               => 'q[g]=x',
      'a nested grouping that is a string'        => 'q[g][0][g]=x',
      'grouping entries that are strings'         => 'q[g][]=x',
      'an indexed grouping entry that is a string' => 'q[g][0]=x',
      'condition entries that are strings'        => 'q[c][]=x',
      'an indexed condition that is a string'     => 'q[c][0]=x',
      'attributes that are a string'              => 'q[c][0][a]=x',
      'an indexed attribute that is a string'     => 'q[c][0][a][0]=x',
      'values that are a string'                  =>
        'q[c][0][a][0][name]=name&q[c][0][p]=eq&q[c][0][v]=x',
      'an indexed value that is a string'         =>
        'q[c][0][a][0][name]=name&q[c][0][p]=eq&q[c][0][v][0]=x',
      'an indexed sort that is a string'          => 'q[s][0]=name',
'a sort entry that is an array'             => 'q[s][][]=x',
'a sort direction that is an array'         => 'q[s][0][name]=name&q[s][0][dir][]=desc',
'a sort direction that is a hash'           => 'q[s][0][name]=name&q[s][0][dir][x]=desc',
'a sort name that is an array'              => 'q[s][0][name][]=name',
'a predicate that is an array'              =>
  'q[c][0][a][0][name]=name&q[c][0][p][]=eq&q[c][0][v][0][value]=x',
'an attribute name that is an array'        =>
  'q[c][0][a][0][name][]=name&q[c][0][p]=eq&q[c][0][v][0][value]=x',
'a combinator that is an array'             => 'q[m][]=or&q[name_eq]=x',
'a grouping combinator that is a hash'      => 'q[g][0][m][x]=or&q[g][0][name_eq]=x'
    }

    shapes.each do |description, query|
      context "with #{description} (#{query})" do
        it 'raises InvalidSearchError from a lenient search' do
          expect { Person.ransack(params(query)).result.to_sql }
            .to raise_error(InvalidSearchError)
        end

        it 'raises InvalidSearchError from a strict search' do
          expect { Person.ransack!(params(query)).result.to_sql }
            .to raise_error(InvalidSearchError)
        end
      end
    end

    it 'names the shape in the message' do
      expect { Person.ransack(params('q[g]=x')) }
        .to raise_error(InvalidSearchError, 'Invalid argument (String) supplied to groupings=')
      expect { Person.ransack(params('q[c][0]=x')) }
        .to raise_error(InvalidSearchError, 'Invalid argument (String) supplied for a condition')
    end

    it 'is still an ArgumentError, for code that rescues that' do
      expect { Person.ransack(params('q[c][0][v]=x')) }.to raise_error(ArgumentError)
    end

    it 'leaves well-formed advanced params alone' do
      query = 'q[c][0][a][0][name]=name&q[c][0][p]=eq&q[c][0][v][0][value]=Ernie'
      expect(Person.ransack(params(query)).result.to_sql)
        .to include "#{name_column} = 'Ernie'"
    end

    context 'a multiparameter fragment given as an array or a hash' do
      it 'is dropped, like any other malformed fragment' do
        s = Person.ransack(params('q[created_at_gt(1i)][]=2020'))
        expect(s.conditions).to be_empty

        s = Person.ransack(params('q[created_at_gt(1i)][x]=2020'))
        expect(s.conditions).to be_empty
      end
    end
  end

  describe Nodes::Sort do
    def name_column
      conn = Person.connection
      "#{conn.quote_table_name('people')}.#{conn.quote_column_name('name')}"
    end

    it 'is ascending when given as a hash without a direction' do
      s = Person.ransack(s: [{ name: 'name' }])
      expect(s.sorts.first.dir).to eq 'asc'
      expect(s.result.to_sql).to include "ORDER BY #{name_column} ASC"
    end

    it 'reads a symbol direction' do
      s = Person.ransack(s: [{ name: 'name', dir: :desc }])
      expect(s.sorts.first.dir).to eq 'desc'
    end

    it 'reads a symbol sort' do
      s = Person.ransack(s: [:name])
      expect(s.sorts.first.name).to eq 'name'
    end
  end
end
