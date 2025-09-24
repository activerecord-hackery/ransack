class Sham
  @@shams = {}
  
  # Over-ride module's built-in name method, so we can re-use it for
  # generating names. This is a bit of a no-no, but we get away with
  # it in this context.
  def self.name(*args, &block)
    method_missing(:name, *args, &block)
  end
  
  def self.method_missing(symbol, *args, &block)
    if block_given?
      @@shams[symbol] = Sham.new(symbol, args.pop || {}, &block)
    else
      sham = @@shams[symbol]
      raise "No sham defined for #{symbol}" if sham.nil?
      sham.fetch_value
    end
  end
  
  def self.clear
    @@shams = {}
  end

  def self.reset(scope = :before_all)
    @@shams.values.each { |sham| sham.reset(scope) }
  end
  
  def self.define(&block)
    Sham.instance_eval(&block)
  end
  
  def initialize(name, options = {}, &block)
    @name      = name
    @generator = block
    @offset    = 0
    @unique    = options.has_key?(:unique) ? options[:unique] : true
    generate_values(12)
  end
  
  def reset(scope)
    if scope == :before_all
      @offset, @before_offset = 0, nil
    elsif @before_offset
      @offset = @before_offset
    else
      @before_offset = @offset
    end
  end
  
  def fetch_value
    # Generate more values if we need them.
    if @offset >= @values.length
      generate_values(2 * @values.length)
      raise "Can't generate more unique values for Sham.#{@name}" if @offset >= @values.length
    end
    result = @values[@offset]
    @offset += 1
    result
  end
    
private
  
  def generate_values(count)
    @values = seeded { (1..count).map(&@generator) }
    @values.uniq! if @unique
  end
  
  def seeded
    begin
      srand(1)
      yield
    ensure
      srand
    end
  end
end
