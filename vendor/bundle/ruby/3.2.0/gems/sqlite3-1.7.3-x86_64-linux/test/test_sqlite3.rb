require 'helper'

module SQLite3
  class TestSQLite3 < SQLite3::TestCase
    def test_libversion
      assert_not_nil SQLite3.libversion
    end

    def test_threadsafe
      assert_not_nil SQLite3.threadsafe
    end

    def test_threadsafe?
      if SQLite3.threadsafe > 0
        assert SQLite3.threadsafe?
      else
        refute SQLite3.threadsafe?
      end
    end

    def test_version_strings
      skip if SQLite3::VERSION.include?("test") # see set-version-to-timestamp rake task
      assert_equal(SQLite3::VERSION, SQLite3::VersionProxy::STRING)
    end

    def test_compiled_version_and_loaded_version
      assert_equal(SQLite3::SQLITE_VERSION, SQLite3::SQLITE_LOADED_VERSION)
    end
  end
end
