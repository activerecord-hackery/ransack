require 'helper'

module SQLite3
  class TestResultSet < SQLite3::TestCase
    def setup
      @db = SQLite3::Database.new ':memory:'
      super
    end

    def teardown
      super
      @db.close
    end

    def test_each_hash
      @db.execute "create table foo ( a integer primary key, b text )"
      list = ('a'..'z').to_a
      list.each do |t|
        @db.execute "insert into foo (b) values (\"#{t}\")"
      end

      rs = @db.prepare('select * from foo').execute
      rs.each_hash do |hash|
        assert_equal list[hash['a'] - 1], hash['b']
      end
      rs.close
    end

    def test_next_hash
      @db.execute "create table foo ( a integer primary key, b text )"
      list = ('a'..'z').to_a
      list.each do |t|
        @db.execute "insert into foo (b) values (\"#{t}\")"
      end

      rs = @db.prepare('select * from foo').execute
      rows = []
      while row = rs.next_hash
        rows << row
      end
      rows.each do |hash|
        assert_equal list[hash['a'] - 1], hash['b']
      end
      rs.close
    end
  end
end
