require 'spec_helper'

module Ransack
  # Keys come from the query string, and `%0A` puts a newline in one. The key
  # patterns used `^` and `$`, which match at line boundaries, so a key with a
  # newline in it either matched a writer name on one of its lines and was
  # sent as a method that does not exist (NoMethodError, a 500), or for a
  # polymorphic `_of_Model_type` segment was read without the rest of its
  # line. A key is now matched as a whole string, so such a key is an unknown
  # key like any other.
  describe 'a search key with a newline in it' do
    it 'is ignored inside a condition' do
      %i[ransack ransack!].each do |m|
        s = Person.public_send(m, c: [{ "zzz\na" => [{ name: 'name' }], p: 'eq', v: ['x'] }])
        expect(s.result.to_sql).not_to include 'WHERE'
        s = Person.public_send(m, c: [{ a: [{ name: 'name' }], "p\nzzz" => 'eq', v: ['x'] }])
        expect(s.result.to_sql).not_to include 'WHERE'
      end
    end

    it 'is ignored inside a sort, which a strict search then rejects' do
      expect(Person.ransack(s: [{ "zzz\nname" => 'name' }]).result.to_sql)
        .not_to include 'ORDER BY'
      expect { Person.ransack!(s: [{ "zzz\nname" => 'name' }]) }
        .to raise_error(InvalidSearchError, /Invalid sort term/)
    end

    it 'is an unknown search key at the top level' do
      expect(Person.ransack("name_eq\nzzz" => 'x').result.to_sql).not_to include 'WHERE'
      expect { Person.ransack!("name_eq\nzzz" => 'x') }
        .to raise_error(InvalidSearchError, /Invalid search term/)
    end

    it 'does not read a polymorphic type from one line of the key' do
      key = "notable_of_Person_type\nzzz_name_eq"
      expect(Note.ransack(key => 'x').result.to_sql).not_to include 'JOIN'
      expect { Note.ransack!(key => 'x') }.to raise_error(InvalidSearchError)
    end

    it 'leaves the same keys without a newline working' do
      expect(Note.ransack(notable_of_Person_type_name_eq: 'x').result.to_sql)
        .to include 'JOIN'
      expect(Person.ransack(c: [{ a: [{ name: 'name' }], p: 'eq', v: ['x'] }]).result.to_sql)
        .to include 'WHERE'
    end
  end
end
