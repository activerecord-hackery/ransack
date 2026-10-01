require 'spec_helper'

module Ransack
  # A single search key is parsed in time superlinear in its `_`-separated
  # segment count, and the key comes straight from the query string, so an
  # unbounded one is a CPU-exhaustion DoS. Ransack caps the depth at
  # Constants::MAX_KEY_DEPTH and treats anything longer as an unknown key
  # (GHSA-j3f8-w227-4hh8).
  describe 'search key depth limit' do
    def long_key(segments)
      (['a'] * segments).join('_')
    end

    let(:over)  { Constants::MAX_KEY_DEPTH + 50 }
    let(:under) { Constants::MAX_KEY_DEPTH - 1 }

    context 'a condition key past the limit' do
      it 'is dropped from a lenient search' do
        s = Person.ransack("#{long_key(over)}_eq" => '1')
        expect(s.conditions).to be_empty
        expect(s.result.to_sql).not_to include 'aaaa'
      end

      it 'raises InvalidSearchError under a strict search' do
        expect {
          Person.ransack!("#{long_key(over)}_eq" => '1').result.to_sql
        }.to raise_error(InvalidSearchError)
      end

      it 'does not raise SystemStackError or hang' do
        expect {
          Person.ransack("#{long_key(over)}_eq" => '1').result.to_sql
        }.not_to raise_error
      end
    end

    context 'an _and_ / _or_ compound past the limit' do
      it 'is dropped rather than expanded into thousands of conditions' do
        key = (['name'] * over).join('_or_') + '_cont'
        s = Person.ransack(key => 'x')
        expect(s.conditions).to be_empty
      end
    end

    context 'the sort value past the limit' do
      it 'produces no ORDER BY and no error' do
        sql = Person.ransack(s: "#{long_key(over)} asc").result.to_sql
        expect(sql).not_to include 'ORDER BY'
      end
    end

    context 'an advanced-mode attribute name past the limit' do
      it 'is dropped and does not blow the stack' do
        params = { c: [{ a: { '0' => { name: long_key(over) } }, p: 'eq', v: [{ value: '1' }] }] }
        expect { Person.ransack(params).result.to_sql }.not_to raise_error
      end
    end

    context 'keys within the limit still work' do
      it 'runs a simple condition' do
        expect(Person.ransack(name_eq: 'x').result.to_sql).to match(/name/)
      end

      it 'runs a compound just under the limit' do
        key = (['name'] * (under / 2)).join('_or_') + '_cont'
        expect { Person.ransack(key => 'a').result.to_sql }.not_to raise_error
      end

      it 'runs an association condition' do
        expect(Person.ransack(articles_title_eq: 'x').result.to_sql).to include 'JOIN'
      end
    end

    # A quadratic regression would make this key take tens of seconds; the
    # bound keeps it instant. The ceiling is deliberately loose so the test
    # is about complexity, not machine speed.
    it 'stays fast for a hostile key' do
      require 'timeout'
      expect {
        Timeout.timeout(10) do
          Person.ransack("#{long_key(20_000)}_eq" => '1').result.to_sql
        end
      }.not_to raise_error
    end
  end
end
