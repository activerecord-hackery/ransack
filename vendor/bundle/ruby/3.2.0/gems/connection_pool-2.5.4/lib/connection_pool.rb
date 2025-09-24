require "timeout"
require_relative "connection_pool/version"

class ConnectionPool
  class Error < ::RuntimeError; end

  class PoolShuttingDownError < ::ConnectionPool::Error; end

  class TimeoutError < ::Timeout::Error; end
end

# Generic connection pool class for sharing a limited number of objects or network connections
# among many threads.  Note: pool elements are lazily created.
#
# Example usage with block (faster):
#
#    @pool = ConnectionPool.new { Redis.new }
#    @pool.with do |redis|
#      redis.lpop('my-list') if redis.llen('my-list') > 0
#    end
#
# Using optional timeout override (for that single invocation)
#
#    @pool.with(timeout: 2.0) do |redis|
#      redis.lpop('my-list') if redis.llen('my-list') > 0
#    end
#
# Example usage replacing an existing connection (slower):
#
#    $redis = ConnectionPool.wrap { Redis.new }
#
#    def do_work
#      $redis.lpop('my-list') if $redis.llen('my-list') > 0
#    end
#
# Accepts the following options:
# - :size - number of connections to pool, defaults to 5
# - :timeout - amount of time to wait for a connection if none currently available, defaults to 5 seconds
# - :auto_reload_after_fork - automatically drop all connections after fork, defaults to true
#
class ConnectionPool
  DEFAULTS = {size: 5, timeout: 5, auto_reload_after_fork: true}.freeze

  def self.wrap(options, &block)
    Wrapper.new(options, &block)
  end

  if Process.respond_to?(:fork)
    INSTANCES = ObjectSpace::WeakMap.new
    private_constant :INSTANCES

    def self.after_fork
      INSTANCES.values.each do |pool|
        next unless pool.auto_reload_after_fork

        # We're on after fork, so we know all other threads are dead.
        # All we need to do is to ensure the main thread doesn't have a
        # checked out connection
        pool.checkin(force: true)
        pool.reload do |connection|
          # Unfortunately we don't know what method to call to close the connection,
          # so we try the most common one.
          connection.close if connection.respond_to?(:close)
        end
      end
      nil
    end

    if ::Process.respond_to?(:_fork) # MRI 3.1+
      module ForkTracker
        def _fork
          pid = super
          if pid == 0
            ConnectionPool.after_fork
          end
          pid
        end
      end
      Process.singleton_class.prepend(ForkTracker)
    end
  else
    INSTANCES = nil
    private_constant :INSTANCES

    def self.after_fork
      # noop
    end
  end

  def initialize(options = {}, &block)
    raise ArgumentError, "Connection pool requires a block" unless block

    options = DEFAULTS.merge(options)

    @size = Integer(options.fetch(:size))
    @timeout = options.fetch(:timeout)
    @auto_reload_after_fork = options.fetch(:auto_reload_after_fork)

    @available = TimedStack.new(@size, &block)
    @key = :"pool-#{@available.object_id}"
    @key_count = :"pool-#{@available.object_id}-count"
    @discard_key = :"pool-#{@available.object_id}-discard"
    INSTANCES[self] = self if @auto_reload_after_fork && INSTANCES
  end

  def with(options = {})
    Thread.handle_interrupt(Exception => :never) do
      conn = checkout(options)
      begin
        Thread.handle_interrupt(Exception => :immediate) do
          yield conn
        end
      ensure
        checkin
      end
    end
  end
  alias_method :then, :with

  ##
  # Marks the current thread's checked-out connection for discard.
  #
  # When a connection is marked for discard, it will not be returned to the pool
  # when checked in. Instead, the connection will be discarded.
  # This is useful when a connection has become invalid or corrupted
  # and should not be reused.
  #
  # Takes an optional block that will be called with the connection to be discarded.
  # The block should perform any necessary clean-up on the connection.
  #
  # @yield [conn]
  # @yieldparam conn [Object] The connection to be discarded.
  # @yieldreturn [void]
  #
  #
  # Note: This only affects the connection currently checked out by the calling thread.
  # The connection will be discarded when +checkin+ is called.
  #
  # @return [void]
  #
  # @example
  #   pool.with do |conn|
  #     begin
  #       conn.execute("SELECT 1")
  #     rescue SomeConnectionError
  #       pool.discard_current_connection  # Mark connection as bad
  #       raise
  #     end
  #   end
  def discard_current_connection(&block)
    ::Thread.current[@discard_key] = block || proc { |conn| conn }
  end

  def checkout(options = {})
    if ::Thread.current[@key]
      ::Thread.current[@key_count] += 1
      ::Thread.current[@key]
    else
      ::Thread.current[@key_count] = 1
      ::Thread.current[@key] = @available.pop(options[:timeout] || @timeout, options)
    end
  end

  def checkin(force: false)
    if ::Thread.current[@key]
      if ::Thread.current[@key_count] == 1 || force
        if ::Thread.current[@discard_key]
          begin
            @available.decrement_created
            ::Thread.current[@discard_key].call(::Thread.current[@key])
          rescue
            nil
          ensure
            ::Thread.current[@discard_key] = nil
          end
        else
          @available.push(::Thread.current[@key])
        end
        ::Thread.current[@key] = nil
        ::Thread.current[@key_count] = nil
      else
        ::Thread.current[@key_count] -= 1
      end
    elsif !force
      raise ConnectionPool::Error, "no connections are checked out"
    end

    nil
  end

  ##
  # Shuts down the ConnectionPool by passing each connection to +block+ and
  # then removing it from the pool. Attempting to checkout a connection after
  # shutdown will raise +ConnectionPool::PoolShuttingDownError+.
  def shutdown(&block)
    @available.shutdown(&block)
  end

  ##
  # Reloads the ConnectionPool by passing each connection to +block+ and then
  # removing it the pool. Subsequent checkouts will create new connections as
  # needed.
  def reload(&block)
    @available.shutdown(reload: true, &block)
  end

  ## Reaps idle connections that have been idle for over +idle_seconds+.
  # +idle_seconds+ defaults to 60.
  def reap(idle_seconds = 60, &block)
    @available.reap(idle_seconds, &block)
  end

  # Size of this connection pool
  attr_reader :size
  # Automatically drop all connections after fork
  attr_reader :auto_reload_after_fork

  # Number of pool entries available for checkout at this instant.
  def available
    @available.length
  end

  # Number of pool entries created and idle in the pool.
  def idle
    @available.idle
  end
end

require_relative "connection_pool/timed_stack"
require_relative "connection_pool/wrapper"
