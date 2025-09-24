require 'sqlite3/constants'
require 'sqlite3/errors'
require 'sqlite3/pragmas'
require 'sqlite3/statement'
require 'sqlite3/translator'
require 'sqlite3/value'

module SQLite3

  # The Database class encapsulates a single connection to a SQLite3 database.
  # Its usage is very straightforward:
  #
  #   require 'sqlite3'
  #
  #   SQLite3::Database.new( "data.db" ) do |db|
  #     db.execute( "select * from table" ) do |row|
  #       p row
  #     end
  #   end
  #
  # It wraps the lower-level methods provided by the selected driver, and
  # includes the Pragmas module for access to various pragma convenience
  # methods.
  #
  # The Database class provides type translation services as well, by which
  # the SQLite3 data types (which are all represented as strings) may be
  # converted into their corresponding types (as defined in the schemas
  # for their tables). This translation only occurs when querying data from
  # the database--insertions and updates are all still typeless.
  #
  # Furthermore, the Database class has been designed to work well with the
  # ArrayFields module from Ara Howard. If you require the ArrayFields
  # module before performing a query, and if you have not enabled results as
  # hashes, then the results will all be indexible by field name.
  class Database
    attr_reader :collations

    include Pragmas

    class << self

      # Without block works exactly as new.
      # With block, like new closes the database at the end, but unlike new
      # returns the result of the block instead of the database instance.
      def open( *args )
        database = new(*args)

        if block_given?
          begin
            yield database
          ensure
            database.close
          end
        else
          database
        end
      end

      # Quotes the given string, making it safe to use in an SQL statement.
      # It replaces all instances of the single-quote character with two
      # single-quote characters. The modified string is returned.
      def quote( string )
        string.gsub( /'/, "''" )
      end

    end

    # A boolean that indicates whether rows in result sets should be returned
    # as hashes or not. By default, rows are returned as arrays.
    attr_accessor :results_as_hash

    # call-seq: SQLite3::Database.new(file, options = {})
    #
    # Create a new Database object that opens the given file.
    #
    # Supported permissions +options+:
    # - the default mode is <tt>READWRITE | CREATE</tt>
    # - +:readonly+: boolean (default false), true to set the mode to +READONLY+
    # - +:readwrite+: boolean (default false), true to set the mode to +READWRITE+
    # - +:flags+: set the mode to a combination of SQLite3::Constants::Open flags.
    #
    # Supported encoding +options+:
    # - +:utf16+: boolean (default false), is the filename's encoding UTF-16 (only needed if the filename encoding is not UTF_16LE or BE)
    #
    # Other supported +options+:
    # - +:strict+: boolean (default false), disallow the use of double-quoted string literals (see https://www.sqlite.org/quirks.html#double_quoted_string_literals_are_accepted)
    # - +:results_as_hash+: boolean (default false), return rows as hashes instead of arrays
    # - +:type_translation+: boolean (default false), enable type translation
    # - +:default_transaction_mode+: one of +:deferred+ (default), +:immediate+, or +:exclusive+. If a mode is not specified in a call to #transaction, this will be the default transaction mode.
    #
    def initialize file, options = {}, zvfs = nil
      mode = Constants::Open::READWRITE | Constants::Open::CREATE

      file = file.to_path if file.respond_to? :to_path
      if file.encoding == ::Encoding::UTF_16LE || file.encoding == ::Encoding::UTF_16BE || options[:utf16]
        open16 file
      else
        # The three primary flag values for sqlite3_open_v2 are:
        # SQLITE_OPEN_READONLY
        # SQLITE_OPEN_READWRITE
        # SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE -- always used for sqlite3_open and sqlite3_open16
        mode = Constants::Open::READONLY if options[:readonly]

        if options[:readwrite]
          raise "conflicting options: readonly and readwrite" if options[:readonly]
          mode = Constants::Open::READWRITE
        end

        if options[:flags]
          if options[:readonly] || options[:readwrite]
            raise "conflicting options: flags with readonly and/or readwrite"
          end
          mode = options[:flags]
        end

        open_v2 file.encode("utf-8"), mode, zvfs

        if options[:strict]
          disable_quirk_mode
        end
      end

      @tracefunc        = nil
      @authorizer       = nil
      @encoding         = nil
      @busy_handler     = nil
      @collations       = {}
      @functions        = {}
      @results_as_hash  = options[:results_as_hash]
      @type_translation = options[:type_translation]
      @type_translator  = make_type_translator @type_translation
      @readonly         = mode & Constants::Open::READONLY != 0
      @default_transaction_mode = options[:default_transaction_mode] || :deferred

      if block_given?
        begin
          yield self
        ensure
          close
        end
      end
    end

    def type_translation= value # :nodoc:
      warn(<<-eowarn) if $VERBOSE
#{caller[0]} is calling `SQLite3::Database#type_translation=` which is deprecated and will be removed in version 2.0.0.
      eowarn
      @type_translator  = make_type_translator value
      @type_translation = value
    end
    attr_reader :type_translation # :nodoc:

    # Return the type translator employed by this database instance. Each
    # database instance has its own type translator; this allows for different
    # type handlers to be installed in each instance without affecting other
    # instances. Furthermore, the translators are instantiated lazily, so that
    # if a database does not use type translation, it will not be burdened by
    # the overhead of a useless type translator. (See the Translator class.)
    def translator
      @translator ||= Translator.new
    end

    # Installs (or removes) a block that will be invoked for every access
    # to the database. If the block returns 0 (or +nil+), the statement
    # is allowed to proceed. Returning 1 causes an authorization error to
    # occur, and returning 2 causes the access to be silently denied.
    def authorizer( &block )
      self.authorizer = block
    end

    # Returns a Statement object representing the given SQL. This does not
    # execute the statement; it merely prepares the statement for execution.
    #
    # The Statement can then be executed using Statement#execute.
    #
    def prepare sql
      stmt = SQLite3::Statement.new( self, sql )
      return stmt unless block_given?

      begin
        yield stmt
      ensure
        stmt.close unless stmt.closed?
      end
    end

    # Returns the filename for the database named +db_name+.  +db_name+ defaults
    # to "main".  Main return `nil` or an empty string if the database is
    # temporary or in-memory.
    def filename db_name = 'main'
      db_filename db_name
    end

    # Executes the given SQL statement. If additional parameters are given,
    # they are treated as bind variables, and are bound to the placeholders in
    # the query.
    #
    # Note that if any of the values passed to this are hashes, then the
    # key/value pairs are each bound separately, with the key being used as
    # the name of the placeholder to bind the value to.
    #
    # The block is optional. If given, it will be invoked for each row returned
    # by the query. Otherwise, any results are accumulated into an array and
    # returned wholesale.
    #
    # See also #execute2, #query, and #execute_batch for additional ways of
    # executing statements.
    def execute sql, bind_vars = [], *args, &block
      if bind_vars.nil? || !args.empty?
        if args.empty?
          bind_vars = []
        else
          bind_vars = [bind_vars] + args
        end

        warn(<<-eowarn) if $VERBOSE
#{caller[0]} is calling `SQLite3::Database#execute` with nil or multiple bind params without using an array.  Please switch to passing bind parameters as an array. Support for bind parameters as *args will be removed in 2.0.0.
        eowarn
      end

      prepare( sql ) do |stmt|
        stmt.bind_params(bind_vars)
        stmt    = ResultSet.new self, stmt

        if block_given?
          stmt.each do |row|
            yield row
          end
        else
          stmt.to_a
        end
      end
    end

    # Executes the given SQL statement, exactly as with #execute. However, the
    # first row returned (either via the block, or in the returned array) is
    # always the names of the columns. Subsequent rows correspond to the data
    # from the result set.
    #
    # Thus, even if the query itself returns no rows, this method will always
    # return at least one row--the names of the columns.
    #
    # See also #execute, #query, and #execute_batch for additional ways of
    # executing statements.
    def execute2( sql, *bind_vars )
      prepare( sql ) do |stmt|
        result = stmt.execute( *bind_vars )
        if block_given?
          yield stmt.columns
          result.each { |row| yield row }
        else
          return result.inject( [ stmt.columns ] ) { |arr,row|
            arr << row; arr }
        end
      end
    end

    # Executes all SQL statements in the given string. By contrast, the other
    # means of executing queries will only execute the first statement in the
    # string, ignoring all subsequent statements. This will execute each one
    # in turn. The same bind parameters, if given, will be applied to each
    # statement.
    #
    # This always returns +nil+, making it unsuitable for queries that return
    # rows.
    #
    # See also #execute_batch2 for additional ways of
    # executing statements.
    def execute_batch( sql, bind_vars = [], *args )
      # FIXME: remove this stuff later
      unless [Array, Hash].include?(bind_vars.class)
        bind_vars = [bind_vars]
        warn(<<-eowarn) if $VERBOSE
#{caller[0]} is calling `SQLite3::Database#execute_batch` with bind parameters that are not a list of a hash.  Please switch to passing bind parameters as an array or hash. Support for this behavior will be removed in version 2.0.0.
        eowarn
      end

      # FIXME: remove this stuff later
      if bind_vars.nil? || !args.empty?
        if args.empty?
          bind_vars = []
        else
          bind_vars = [nil] + args
        end

        warn(<<-eowarn) if $VERBOSE
#{caller[0]} is calling `SQLite3::Database#execute_batch` with nil or multiple bind params without using an array.  Please switch to passing bind parameters as an array. Support for this behavior will be removed in version 2.0.0.
        eowarn
      end

      sql = sql.strip
      until sql.empty? do
        prepare( sql ) do |stmt|
          unless stmt.closed?
            # FIXME: this should probably use sqlite3's api for batch execution
            # This implementation requires stepping over the results.
            if bind_vars.length == stmt.bind_parameter_count
              stmt.bind_params(bind_vars)
            end
            stmt.step
          end
          sql = stmt.remainder.strip
        end
      end
      # FIXME: we should not return `nil` as a success return value
      nil
    end

    # Executes all SQL statements in the given string. By contrast, the other
    # means of executing queries will only execute the first statement in the
    # string, ignoring all subsequent statements. This will execute each one
    # in turn. Bind parameters cannot be passed to #execute_batch2.
    #
    # If a query is made, all values will be returned as strings.
    # If no query is made, an empty array will be returned.
    #
    # Because all values except for 'NULL' are returned as strings,
    # a block can be passed to parse the values accordingly.
    #
    # See also #execute_batch for additional ways of
    # executing statements.
    def execute_batch2(sql, &block)
      if block_given?
        result = exec_batch(sql, @results_as_hash)
        result.map do |val|
          yield val
        end
      else
        exec_batch(sql, @results_as_hash)
      end
    end

    # This is a convenience method for creating a statement, binding
    # parameters to it, and calling execute:
    #
    #   result = db.query( "select * from foo where a=?", [5])
    #   # is the same as
    #   result = db.prepare( "select * from foo where a=?" ).execute( 5 )
    #
    # You must be sure to call +close+ on the ResultSet instance that is
    # returned, or you could have problems with locks on the table. If called
    # with a block, +close+ will be invoked implicitly when the block
    # terminates.
    def query( sql, bind_vars = [], *args )

      if bind_vars.nil? || !args.empty?
        if args.empty?
          bind_vars = []
        else
          bind_vars = [bind_vars] + args
        end

        warn(<<-eowarn) if $VERBOSE
#{caller[0]} is calling `SQLite3::Database#query` with nil or multiple bind params without using an array.  Please switch to passing bind parameters as an array. Support for this will be removed in version 2.0.0.
        eowarn
      end

      result = prepare( sql ).execute( bind_vars )
      if block_given?
        begin
          yield result
        ensure
          result.close
        end
      else
        return result
      end
    end

    # A convenience method for obtaining the first row of a result set, and
    # discarding all others. It is otherwise identical to #execute.
    #
    # See also #get_first_value.
    def get_first_row( sql, *bind_vars )
      execute( sql, *bind_vars ).first
    end

    # A convenience method for obtaining the first value of the first row of a
    # result set, and discarding all other values and rows. It is otherwise
    # identical to #execute.
    #
    # See also #get_first_row.
    def get_first_value( sql, *bind_vars )
      query( sql, bind_vars ) do |rs|
        if (row = rs.next)
          return @results_as_hash ? row[rs.columns[0]] : row[0]
        end
      end
      nil
    end

    alias :busy_timeout :busy_timeout=

    # Creates a new function for use in SQL statements. It will be added as
    # +name+, with the given +arity+. (For variable arity functions, use
    # -1 for the arity.)
    #
    # The block should accept at least one parameter--the FunctionProxy
    # instance that wraps this function invocation--and any other
    # arguments it needs (up to its arity).
    #
    # The block does not return a value directly. Instead, it will invoke
    # the FunctionProxy#result= method on the +func+ parameter and
    # indicate the return value that way.
    #
    # Example:
    #
    #   db.create_function( "maim", 1 ) do |func, value|
    #     if value.nil?
    #       func.result = nil
    #     else
    #       func.result = value.split(//).sort.join
    #     end
    #   end
    #
    #   puts db.get_first_value( "select maim(name) from table" )
    def create_function name, arity, text_rep=Constants::TextRep::UTF8, &block
      define_function_with_flags(name, text_rep) do |*args|
        fp = FunctionProxy.new
        block.call(fp, *args)
        fp.result
      end
      self
    end

    # Creates a new aggregate function for use in SQL statements. Aggregate
    # functions are functions that apply over every row in the result set,
    # instead of over just a single row. (A very common aggregate function
    # is the "count" function, for determining the number of rows that match
    # a query.)
    #
    # The new function will be added as +name+, with the given +arity+. (For
    # variable arity functions, use -1 for the arity.)
    #
    # The +step+ parameter must be a proc object that accepts as its first
    # parameter a FunctionProxy instance (representing the function
    # invocation), with any subsequent parameters (up to the function's arity).
    # The +step+ callback will be invoked once for each row of the result set.
    #
    # The +finalize+ parameter must be a +proc+ object that accepts only a
    # single parameter, the FunctionProxy instance representing the current
    # function invocation. It should invoke FunctionProxy#result= to
    # store the result of the function.
    #
    # Example:
    #
    #   db.create_aggregate( "lengths", 1 ) do
    #     step do |func, value|
    #       func[ :total ] ||= 0
    #       func[ :total ] += ( value ? value.length : 0 )
    #     end
    #
    #     finalize do |func|
    #       func.result = func[ :total ] || 0
    #     end
    #   end
    #
    #   puts db.get_first_value( "select lengths(name) from table" )
    #
    # See also #create_aggregate_handler for a more object-oriented approach to
    # aggregate functions.
    def create_aggregate( name, arity, step=nil, finalize=nil,
      text_rep=Constants::TextRep::ANY, &block )

      proxy = Class.new do
        def self.step( &block )
          define_method(:step_with_ctx, &block)
        end

        def self.finalize( &block )
          define_method(:finalize_with_ctx, &block)
        end
      end

      if block_given?
        proxy.instance_eval(&block)
      else
        proxy.class_eval do
          define_method(:step_with_ctx, step)
          define_method(:finalize_with_ctx, finalize)
        end
      end

      proxy.class_eval do
        # class instance variables
        @name = name
        @arity = arity

        def self.name
          @name
        end

        def self.arity
          @arity
        end

        def initialize
          @ctx = FunctionProxy.new
        end

        def step( *args )
          step_with_ctx(@ctx, *args)
        end

        def finalize
          finalize_with_ctx(@ctx)
          @ctx.result
        end
      end
      define_aggregator2(proxy, name)
    end

    # This is another approach to creating an aggregate function (see
    # #create_aggregate). Instead of explicitly specifying the name,
    # callbacks, arity, and type, you specify a factory object
    # (the "handler") that knows how to obtain all of that information. The
    # handler should respond to the following messages:
    #
    # +arity+:: corresponds to the +arity+ parameter of #create_aggregate. This
    #           message is optional, and if the handler does not respond to it,
    #           the function will have an arity of -1.
    # +name+:: this is the name of the function. The handler _must_ implement
    #          this message.
    # +new+:: this must be implemented by the handler. It should return a new
    #         instance of the object that will handle a specific invocation of
    #         the function.
    #
    # The handler instance (the object returned by the +new+ message, described
    # above), must respond to the following messages:
    #
    # +step+:: this is the method that will be called for each step of the
    #          aggregate function's evaluation. It should implement the same
    #          signature as the +step+ callback for #create_aggregate.
    # +finalize+:: this is the method that will be called to finalize the
    #              aggregate function's evaluation. It should implement the
    #              same signature as the +finalize+ callback for
    #              #create_aggregate.
    #
    # Example:
    #
    #   class LengthsAggregateHandler
    #     def self.arity; 1; end
    #     def self.name; 'lengths'; end
    #
    #     def initialize
    #       @total = 0
    #     end
    #
    #     def step( ctx, name )
    #       @total += ( name ? name.length : 0 )
    #     end
    #
    #     def finalize( ctx )
    #       ctx.result = @total
    #     end
    #   end
    #
    #   db.create_aggregate_handler( LengthsAggregateHandler )
    #   puts db.get_first_value( "select lengths(name) from A" )
    def create_aggregate_handler( handler )
      # This is a compatibility shim so the (basically pointless) FunctionProxy
      # "ctx" object is passed as first argument to both step() and finalize().
      # Now its up to the library user whether he prefers to store his
      # temporaries as instance variables or fields in the FunctionProxy.
      # The library user still must set the result value with
      # FunctionProxy.result= as there is no backwards compatible way to
      # change this.
      proxy = Class.new(handler) do
        def initialize
          super
          @fp = FunctionProxy.new
        end

        def step( *args )
          super(@fp, *args)
        end

        def finalize
          super(@fp)
          @fp.result
        end
      end
      define_aggregator2(proxy, proxy.name)
      self
    end

    # Define an aggregate function named +name+ using a object template
    # object +aggregator+. +aggregator+ must respond to +step+ and +finalize+.
    # +step+ will be called with row information and +finalize+ must return the
    # return value for the aggregator function.
    #
    # _API Change:_ +aggregator+ must also implement +clone+. The provided
    # +aggregator+ object will serve as template that is cloned to provide the
    # individual instances of the aggregate function. Regular ruby objects
    # already provide a suitable +clone+.
    # The functions arity is the arity of the +step+ method.
    def define_aggregator( name, aggregator )
      # Previously, this has been implemented in C. Now this is just yet
      # another compatibility shim
      proxy = Class.new do
        @template = aggregator
        @name = name

        def self.template
          @template
        end

        def self.name
          @name
        end

        def self.arity
          # this is what sqlite3_obj_method_arity did before
          @template.method(:step).arity
        end

        def initialize
          @klass = self.class.template.clone
        end

        def step(*args)
          @klass.step(*args)
        end

        def finalize
          @klass.finalize
        end
      end
      define_aggregator2(proxy, name)
      self
    end

    # Begins a new transaction. Note that nested transactions are not allowed
    # by SQLite, so attempting to nest a transaction will result in a runtime
    # exception.
    #
    # The +mode+ parameter may be either <tt>:deferred</tt>,
    # <tt>:immediate</tt>, or <tt>:exclusive</tt>.
    # If `nil` is specified, the default transaction mode, which was
    # passed to #initialize, is used.
    #
    # If a block is given, the database instance is yielded to it, and the
    # transaction is committed when the block terminates. If the block
    # raises an exception, a rollback will be performed instead. Note that if
    # a block is given, #commit and #rollback should never be called
    # explicitly or you'll get an error when the block terminates.
    #
    # If a block is not given, it is the caller's responsibility to end the
    # transaction explicitly, either by calling #commit, or by calling
    # #rollback.
    def transaction( mode = nil )
      mode = @default_transaction_mode if mode.nil?
      execute "begin #{mode.to_s} transaction"

      if block_given?
        abort = false
        begin
          yield self
        rescue
          abort = true
          raise
        ensure
          abort and rollback or commit
        end
      end

      true
    end

    # Commits the current transaction. If there is no current transaction,
    # this will cause an error to be raised. This returns +true+, in order
    # to allow it to be used in idioms like
    # <tt>abort? and rollback or commit</tt>.
    def commit
      execute "commit transaction"
      true
    end

    # Rolls the current transaction back. If there is no current transaction,
    # this will cause an error to be raised. This returns +true+, in order
    # to allow it to be used in idioms like
    # <tt>abort? and rollback or commit</tt>.
    def rollback
      execute "rollback transaction"
      true
    end

    # Returns +true+ if the database has been open in readonly mode
    # A helper to check before performing any operation
    def readonly?
      @readonly
    end

    # A helper class for dealing with custom functions (see #create_function,
    # #create_aggregate, and #create_aggregate_handler). It encapsulates the
    # opaque function object that represents the current invocation. It also
    # provides more convenient access to the API functions that operate on
    # the function object.
    #
    # This class will almost _always_ be instantiated indirectly, by working
    # with the create methods mentioned above.
    class FunctionProxy
      attr_accessor :result

      # Create a new FunctionProxy that encapsulates the given +func+ object.
      # If context is non-nil, the functions context will be set to that. If
      # it is non-nil, it must quack like a Hash. If it is nil, then none of
      # the context functions will be available.
      def initialize
        @result   = nil
        @context  = {}
      end

      # Set the result of the function to the given error message.
      # The function will then return that error.
      def set_error( error )
        @driver.result_error( @func, error.to_s, -1 )
      end

      # (Only available to aggregate functions.) Returns the number of rows
      # that the aggregate has processed so far. This will include the current
      # row, and so will always return at least 1.
      def count
        @driver.aggregate_count( @func )
      end

      # Returns the value with the given key from the context. This is only
      # available to aggregate functions.
      def []( key )
        @context[ key ]
      end

      # Sets the value with the given key in the context. This is only
      # available to aggregate functions.
      def []=( key, value )
        @context[ key ] = value
      end
    end

    # Translates a +row+ of data from the database with the given +types+
    def translate_from_db types, row
      @type_translator.call types, row
    end

    private

    NULL_TRANSLATOR = lambda { |_, row| row }

    def make_type_translator should_translate
      if should_translate
        lambda { |types, row|
          types.zip(row).map do |type, value|
            translator.translate( type, value )
          end
        }
      else
        NULL_TRANSLATOR
      end
    end
  end
end
