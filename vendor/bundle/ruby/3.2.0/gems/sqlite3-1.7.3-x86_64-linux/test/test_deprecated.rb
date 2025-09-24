require 'helper'

module SQLite3
  class TestDeprecated < SQLite3::TestCase
    def setup
      super
      @warn_before = $-w
      $-w = false
      @db = SQLite3::Database.new(':memory:')
      @db.execute 'CREATE TABLE test_table (name text, age int)'
    end

    def teardown
      super
      $-w = @warn_before
      @db.close
    end

    def test_query_with_many_bind_params_not_nil
      rs = @db.query('select ?, ?', 1, 2)
      assert_equal [[1, 2]], rs.to_a
      rs.close
    end

    def test_execute_with_many_bind_params_not_nil
      assert_equal [[1, 2]], @db.execute("select ?, ?", 1, 2).to_a
    end

    def test_query_with_many_bind_params
      rs = @db.query("select ?, ?", nil, 1)
      assert_equal [[nil, 1]], rs.to_a
      rs.close
    end

    def test_query_with_nil_bind_params
      rs = @db.query("select 'foo'", nil)
      assert_equal [['foo']], rs.to_a
      rs.close
    end

    def test_execute_with_many_bind_params
      assert_equal [[nil, 1]], @db.execute("select ?, ?", nil, 1)
    end

    def test_execute_with_nil_bind_params
      assert_equal [['foo']], @db.execute("select 'foo'", nil)
    end
  end
end
