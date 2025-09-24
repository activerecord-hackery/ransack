require 'helper'

module SQLite3
  class TestDatabaseFlags < SQLite3::TestCase
    def setup
      File.unlink 'test-flags.db' if File.exist?('test-flags.db')
      @db = SQLite3::Database.new('test-flags.db')
      @db.execute("CREATE TABLE foos (id integer)")
      @db.close
    end

    def teardown
      @db.close unless @db.closed?
      File.unlink 'test-flags.db' if File.exist?('test-flags.db')
    end

    def test_open_database_flags_constants
      defined_to_date = [:READONLY, :READWRITE, :CREATE, :DELETEONCLOSE,
                         :EXCLUSIVE, :MAIN_DB, :TEMP_DB, :TRANSIENT_DB,
                         :MAIN_JOURNAL, :TEMP_JOURNAL, :SUBJOURNAL,
                         :MASTER_JOURNAL, :NOMUTEX, :FULLMUTEX]
      if SQLite3::SQLITE_VERSION_NUMBER > 3007002
        defined_to_date += [:AUTOPROXY, :SHAREDCACHE, :PRIVATECACHE, :WAL]
      end
      if SQLite3::SQLITE_VERSION_NUMBER > 3007007
        defined_to_date += [:URI]
      end
      if SQLite3::SQLITE_VERSION_NUMBER > 3007013
        defined_to_date += [:MEMORY]
      end
      assert defined_to_date.sort == SQLite3::Constants::Open.constants.sort
    end

    def test_open_database_flags_conflicts_with_readonly
      assert_raise(RuntimeError) do
        @db = SQLite3::Database.new('test-flags.db', :flags => 2, :readonly => true)
      end
    end

    def test_open_database_flags_conflicts_with_readwrite
      assert_raise(RuntimeError) do
        @db = SQLite3::Database.new('test-flags.db', :flags => 2, :readwrite => true)
      end
    end

    def test_open_database_readonly_flags
      @db = SQLite3::Database.new('test-flags.db', :flags => SQLite3::Constants::Open::READONLY)
      assert @db.readonly?
    end

    def test_open_database_readwrite_flags
      @db = SQLite3::Database.new('test-flags.db', :flags => SQLite3::Constants::Open::READWRITE)
      assert !@db.readonly?
    end

    def test_open_database_readonly_flags_cant_open
      File.unlink 'test-flags.db'
      assert_raise(SQLite3::CantOpenException) do
        @db = SQLite3::Database.new('test-flags.db', :flags => SQLite3::Constants::Open::READONLY)
      end
    end

    def test_open_database_readwrite_flags_cant_open
      File.unlink 'test-flags.db'
      assert_raise(SQLite3::CantOpenException) do
        @db = SQLite3::Database.new('test-flags.db', :flags => SQLite3::Constants::Open::READWRITE)
      end
    end

    def test_open_database_misuse_flags
      assert_raise(SQLite3::MisuseException) do
        flags = SQLite3::Constants::Open::READONLY | SQLite3::Constants::Open::READWRITE # <== incompatible flags
        @db = SQLite3::Database.new('test-flags.db', :flags => flags)
      end
    end

    def test_open_database_create_flags
      File.unlink 'test-flags.db'
      flags = SQLite3::Constants::Open::READWRITE | SQLite3::Constants::Open::CREATE
      @db = SQLite3::Database.new('test-flags.db', :flags => flags) do |db|
        db.execute("CREATE TABLE foos (id integer)")
        db.execute("INSERT INTO foos (id) VALUES (12)")
      end
      assert File.exist?('test-flags.db')
    end

    def test_open_database_exotic_flags
      flags = SQLite3::Constants::Open::READWRITE | SQLite3::Constants::Open::CREATE
      exotic_flags = SQLite3::Constants::Open::NOMUTEX | SQLite3::Constants::Open::TEMP_DB
      @db = SQLite3::Database.new('test-flags.db', :flags => flags | exotic_flags)
      @db.execute("INSERT INTO foos (id) VALUES (12)")
      assert @db.changes == 1
    end
  end
end
