module Mysql2
  class Error < StandardError
    ENCODE_OPTS = {
      undef: :replace,
      invalid: :replace,
      replace: '?'.freeze,
    }.freeze

    ConnectionError = Class.new(Error)
    TimeoutError = Class.new(Error)

    CODES = {
      1205 => TimeoutError, # ER_LOCK_WAIT_TIMEOUT

      1044 => ConnectionError, # ER_DBACCESS_DENIED_ERROR
      1045 => ConnectionError, # ER_ACCESS_DENIED_ERROR
      1152 => ConnectionError, # ER_ABORTING_CONNECTION
      1153 => ConnectionError, # ER_NET_PACKET_TOO_LARGE
      1154 => ConnectionError, # ER_NET_READ_ERROR_FROM_PIPE
      1155 => ConnectionError, # ER_NET_FCNTL_ERROR
      1156 => ConnectionError, # ER_NET_PACKETS_OUT_OF_ORDER
      1157 => ConnectionError, # ER_NET_UNCOMPRESS_ERROR
      1158 => ConnectionError, # ER_NET_READ_ERROR
      1159 => ConnectionError, # ER_NET_READ_INTERRUPTED
      1160 => ConnectionError, # ER_NET_ERROR_ON_WRITE
      1161 => ConnectionError, # ER_NET_WRITE_INTERRUPTED
      1927 => ConnectionError, # ER_CONNECTION_KILLED

      2001 => ConnectionError, # CR_SOCKET_CREATE_ERROR
      2002 => ConnectionError, # CR_CONNECTION_ERROR
      2003 => ConnectionError, # CR_CONN_HOST_ERROR
      2004 => ConnectionError, # CR_IPSOCK_ERROR
      2005 => ConnectionError, # CR_UNKNOWN_HOST
      2006 => ConnectionError, # CR_SERVER_GONE_ERROR
      2007 => ConnectionError, # CR_VERSION_ERROR
      2009 => ConnectionError, # CR_WRONG_HOST_INFO
      2012 => ConnectionError, # CR_SERVER_HANDSHAKE_ERR
      2013 => ConnectionError, # CR_SERVER_LOST
      2020 => ConnectionError, # CR_NET_PACKET_TOO_LARGE
      2026 => ConnectionError, # CR_SSL_CONNECTION_ERROR
      2027 => ConnectionError, # CR_MALFORMED_PACKET
      2047 => ConnectionError, # CR_CONN_UNKNOW_PROTOCOL
      2048 => ConnectionError, # CR_INVALID_CONN_HANDLE
      2049 => ConnectionError, # CR_UNUSED_1
    }.freeze

    attr_reader :error_number, :sql_state

    # Mysql gem compatibility
    alias errno error_number
    alias error message

    def initialize(msg, server_version = nil, error_number = nil, sql_state = nil)
      @server_version = server_version
      @error_number = error_number
      @sql_state = sql_state ? sql_state.encode(**ENCODE_OPTS) : nil

      super(clean_message(msg))
    end

    def self.new_with_args(msg, server_version, error_number, sql_state)
      error_class = CODES.fetch(error_number, self)
      error_class.new(msg, server_version, error_number, sql_state)
    end

    private

    # In MySQL 5.5+ error messages are always constructed server-side as UTF-8
    # then returned in the encoding set by the `character_set_results` system
    # variable.
    #
    # See http://dev.mysql.com/doc/refman/5.5/en/charset-errors.html for
    # more context.
    #
    # Before MySQL 5.5 error message template strings are in whatever encoding
    # is associated with the error message language.
    # See http://dev.mysql.com/doc/refman/5.1/en/error-message-language.html
    # for more information.
    #
    # The issue is that the user-data inserted in the message could potentially
    # be in any encoding MySQL supports and is insert into the latin1, euckr or
    # koi8r string raw. Meaning there's a high probability the string will be
    # corrupt encoding-wise.
    #
    # See http://dev.mysql.com/doc/refman/5.1/en/charset-errors.html for
    # more information.
    #
    # So in an attempt to make sure the error message string is always in a valid
    # encoding, we'll assume UTF-8 and clean the string of anything that's not a
    # valid UTF-8 character.
    #
    # Returns a valid UTF-8 string.
    def clean_message(message)
      if @server_version && @server_version > 50500
        message.encode(**ENCODE_OPTS)
      else
        message.encode(Encoding::UTF_8, **ENCODE_OPTS)
      end
    end
  end
end
