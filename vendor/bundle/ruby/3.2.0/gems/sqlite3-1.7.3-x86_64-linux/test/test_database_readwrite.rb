require 'helper'

module SQLite3
  class TestDatabaseReadwrite < SQLite3::TestCase
    def setup
      File.unlink 'test-readwrite.db' if File.exist?('test-readwrite.db')
      @db = SQLite3::Database.new('test-readwrite.db')
      @db.execute("CREATE TABLE foos (id integer)")
      @db.close
    end

    def teardown
      @db.close unless @db.closed?
      File.unlink 'test-readwrite.db' if File.exist?('test-readwrite.db')
    end

    def test_open_readwrite_database
      @db = SQLite3::Database.new('test-readwrite.db', :readwrite => true)
      assert !@db.readonly?
    end

    def test_open_readwrite_readonly_database
      assert_raise(RuntimeError) do
        @db = SQLite3::Database.new('test-readwrite.db', :readwrite => true, :readonly => true)
      end
    end

    def test_open_readwrite_not_exists_database
      File.unlink 'test-readwrite.db'
      assert_raise(SQLite3::CantOpenException) do
        @db = SQLite3::Database.new('test-readwrite.db', :readonly => true)
      end
    end

    def test_insert_readwrite_database
      @db = SQLite3::Database.new('test-readwrite.db', :readwrite => true)
      @db.execute("INSERT INTO foos (id) VALUES (12)")
      assert @db.changes == 1
    end
  end
end
