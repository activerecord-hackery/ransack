require 'helper'

module SQLite3
  class TestPragmas < SQLite3::TestCase
    def setup
      super
      @db = SQLite3::Database.new(":memory:")
    end

    def test_get_boolean_pragma
      refute(@db.get_boolean_pragma("read_uncommitted"))
    end

    def test_set_boolean_pragma
      @db.set_boolean_pragma("read_uncommitted", 1)

      assert(@db.get_boolean_pragma("read_uncommitted"))
    ensure
      @db.set_boolean_pragma("read_uncommitted", 0)
    end
  end
end
