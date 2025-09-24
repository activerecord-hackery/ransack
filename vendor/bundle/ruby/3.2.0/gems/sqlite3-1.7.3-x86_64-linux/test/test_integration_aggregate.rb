require 'helper'

class TC_Integration_Aggregate < SQLite3::TestCase
  def setup
    @db = SQLite3::Database.new(":memory:")
    @db.transaction do
      @db.execute "create table foo ( a integer primary key, b text, c integer )"
      @db.execute "insert into foo ( b, c ) values ( 'foo', 10 )"
      @db.execute "insert into foo ( b, c ) values ( 'bar', 11 )"
      @db.execute "insert into foo ( b, c ) values ( 'bar', 12 )"
    end
  end

  def teardown
    @db.close
  end

  def test_create_aggregate_without_block
    step = proc do |ctx,a|
      ctx[:sum] ||= 0
      ctx[:sum] += a.to_i
    end

    final = proc { |ctx| ctx.result = ctx[:sum] }

    @db.create_aggregate( "accumulate", 1, step, final )

    value = @db.get_first_value( "select accumulate(a) from foo" )
    assert_equal 6, value

    # calling #get_first_value twice don't add up to the latest result
    value = @db.get_first_value( "select accumulate(a) from foo" )
    assert_equal 6, value
  end

  def test_create_aggregate_with_block
    @db.create_aggregate( "accumulate", 1 ) do
      step do |ctx,a|
        ctx[:sum] ||= 0
        ctx[:sum] += a.to_i
      end

      finalize { |ctx| ctx.result = ctx[:sum] }
    end

    value = @db.get_first_value( "select accumulate(a) from foo" )
    assert_equal 6, value
  end

  def test_create_aggregate_with_group_by
    @db.create_aggregate( "accumulate", 1 ) do
      step do |ctx,a|
        ctx[:sum] ||= 0
        ctx[:sum] += a.to_i
      end

      finalize { |ctx| ctx.result = ctx[:sum] }
    end

    values = @db.execute( "select b, accumulate(c) from foo group by b order by b" )
    assert_equal "bar", values[0][0]
    assert_equal 23, values[0][1]
    assert_equal "foo", values[1][0]
    assert_equal 10, values[1][1]
  end

  def test_create_aggregate_with_the_same_function_twice_in_a_query
    @db.create_aggregate( "accumulate", 1 ) do
      step do |ctx,a|
        ctx[:sum] ||= 0
        ctx[:sum] += a.to_i
      end

      finalize { |ctx| ctx.result = ctx[:sum] }
    end

    values = @db.get_first_row( "select accumulate(a), accumulate(c) from foo" )
    assert_equal 6, values[0]
    assert_equal 33, values[1]
  end

  def test_create_aggregate_with_two_different_functions
    @db.create_aggregate( "accumulate", 1 ) do
      step do |ctx,a|
        ctx[:sum] ||= 0
        ctx[:sum] += a.to_i
      end

      finalize { |ctx| ctx.result = ctx[:sum] }
    end

    @db.create_aggregate( "multiply", 1 ) do
      step do |ctx,a|
        ctx[:sum] ||= 1
        ctx[:sum] *= a.to_i
      end

      finalize { |ctx| ctx.result = ctx[:sum] }
    end

    GC.start
    
    values = @db.get_first_row( "select accumulate(a), multiply(c) from foo" )
    assert_equal 6, values[0]
    assert_equal 1320, values[1]

    value = @db.get_first_value( "select accumulate(c) from foo")
    assert_equal 33, value

    value = @db.get_first_value( "select multiply(a) from foo")
    assert_equal 6, value
  end

  def test_create_aggregate_overwrite_function
    @db.create_aggregate( "accumulate", 1 ) do
      step do |ctx,a|
        ctx[:sum] ||= 0
        ctx[:sum] += a.to_i
      end

      finalize { |ctx| ctx.result = ctx[:sum] }
    end

    value = @db.get_first_value( "select accumulate(c) from foo")
    assert_equal 33, value

    GC.start

    @db.create_aggregate( "accumulate", 1 ) do
      step do |ctx,a|
        ctx[:sum] ||= 1
        ctx[:sum] *= a.to_i
      end

      finalize { |ctx| ctx.result = ctx[:sum] }
    end

    value = @db.get_first_value( "select accumulate(c) from foo")
    assert_equal 1320, value
  end

  def test_create_aggregate_overwrite_function_with_different_arity
    @db.create_aggregate( "accumulate", -1 ) do
      step do |ctx,*args|
        ctx[:sum] ||= 0
        args.each { |a| ctx[:sum] += a.to_i }
      end

      finalize { |ctx| ctx.result = ctx[:sum] }
    end

    @db.create_aggregate( "accumulate", 2 ) do
      step do |ctx,a,b|
        ctx[:sum] ||= 1
        ctx[:sum] *= (a.to_i + b.to_i)
      end

      finalize { |ctx| ctx.result = ctx[:sum] }
    end

    GC.start

    values = @db.get_first_row( "select accumulate(c), accumulate(a,c) from foo")
    assert_equal 33, values[0]
    assert_equal 2145, values[1]
  end

  def test_create_aggregate_with_invalid_arity
    assert_raise ArgumentError do
      @db.create_aggregate( "accumulate", 1000 ) do
        step {|ctx,*args| }
        finalize { |ctx| }
      end
    end
  end

  class CustomException < Exception
  end

  def test_create_aggregate_with_exception_in_step
    @db.create_aggregate( "raiseexception", 1 ) do
      step do |ctx,a|
        raise CustomException.new( "bogus aggregate handler" )
      end

      finalize { |ctx| ctx.result = 42 }
    end

    assert_raise CustomException do
      @db.get_first_value( "select raiseexception(a) from foo")
    end
  end

  def test_create_aggregate_with_exception_in_finalize
    @db.create_aggregate( "raiseexception", 1 ) do
      step do |ctx,a|
        raise CustomException.new( "bogus aggregate handler" )
      end

      finalize do |ctx|
        raise CustomException.new( "bogus aggregate handler" )
      end
    end

    assert_raise CustomException do
      @db.get_first_value( "select raiseexception(a) from foo")
    end
  end

  def test_create_aggregate_with_no_data
    @db.create_aggregate( "accumulate", 1 ) do
      step do |ctx,a|
        ctx[:sum] ||= 0
        ctx[:sum] += a.to_i
      end

      finalize { |ctx| ctx.result = ctx[:sum] || 0 }
    end

    value = @db.get_first_value(
      "select accumulate(a) from foo where a = 100" )
    assert_equal 0, value
  end

  class AggregateHandler
    class << self
      def arity; 1; end
      def text_rep; SQLite3::Constants::TextRep::ANY; end
      def name; "multiply"; end
    end
    def step(ctx, a)
      ctx[:buffer] ||= 1
      ctx[:buffer] *= a.to_i
    end
    def finalize(ctx); ctx.result = ctx[:buffer]; end
  end

  def test_aggregate_initialized_twice
    initialized = 0
    handler = Class.new(AggregateHandler) do
      define_method(:initialize) do
        initialized += 1
        super()
      end
    end

    @db.create_aggregate_handler handler
    @db.get_first_value( "select multiply(a) from foo" )
    @db.get_first_value( "select multiply(a) from foo" )
    assert_equal 2, initialized
  end

  def test_create_aggregate_handler_call_with_wrong_arity
    @db.create_aggregate_handler AggregateHandler

    assert_raise(SQLite3::SQLException) do
     @db.get_first_value( "select multiply(a,c) from foo" )
   end
  end

  class RaiseExceptionStepAggregateHandler
    class << self
      def arity; 1; end
      def text_rep; SQLite3::Constants::TextRep::ANY; end
      def name; "raiseexception"; end
    end
    def step(ctx, a)
      raise CustomException.new( "bogus aggregate handler" )
    end
    def finalize(ctx); ctx.result = nil; end
  end

  def test_create_aggregate_handler_with_exception_step
    @db.create_aggregate_handler RaiseExceptionStepAggregateHandler
    assert_raise CustomException do
      @db.get_first_value( "select raiseexception(a) from foo")
    end
  end

  class RaiseExceptionNewAggregateHandler
    class << self
      def name; "raiseexception"; end
    end
    def initialize
      raise CustomException.new( "bogus aggregate handler" )
    end
    def step(ctx, a); end
    def finalize(ctx); ctx.result = nil; end
  end

  def test_create_aggregate_handler_with_exception_new
    @db.create_aggregate_handler RaiseExceptionNewAggregateHandler
    assert_raise CustomException do
      @db.get_first_value( "select raiseexception(a) from foo")
    end
  end

  def test_create_aggregate_handler
    @db.create_aggregate_handler AggregateHandler
    value = @db.get_first_value( "select multiply(a) from foo" )
    assert_equal 6, value
  end

  class AccumulateAggregator
    def step(*args)
      @sum ||= 0
      args.each { |a| @sum += a.to_i }
    end

    def finalize
      @sum
    end
  end

  class AccumulateAggregator2
    def step(a, b)
      @sum ||= 1
      @sum *= (a.to_i + b.to_i)
    end

    def finalize
      @sum
    end
  end

  def test_define_aggregator_with_two_different_arities
    @db.define_aggregator( "accumulate", AccumulateAggregator.new )
    @db.define_aggregator( "accumulate", AccumulateAggregator2.new )

    GC.start

    values = @db.get_first_row( "select accumulate(c), accumulate(a,c) from foo")
    assert_equal 33, values[0]
    assert_equal 2145, values[1]
  end
end
