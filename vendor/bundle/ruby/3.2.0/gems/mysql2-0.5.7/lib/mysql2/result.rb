module Mysql2
  class Result
    attr_reader :server_flags

    include Enumerable
  end
end
