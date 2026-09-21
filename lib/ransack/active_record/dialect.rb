module Ransack
  module ActiveRecord
    # The SQL dialect behind a model's connection.
    #
    # Nearly everything Ransack generates goes through Arel, which already
    # knows how to render for each database. The two exceptions are recorded
    # here: whether LIKE can be made case-insensitive without wrapping the
    # column in LOWER(), and which function counts characters in a string.
    #
    # The dialect is read from the adapter class's ancestry rather than its
    # name, so an adapter that subclasses one of Rails' own — PostGIS on top
    # of PostgreSQL, for example — is treated like its parent without Ransack
    # having to know it exists. An adapter that subclasses none of them gets
    # the generic dialect, which uses only standard SQL. `config.dialect`
    # overrides the detection for an adapter that should be treated as one of
    # the known dialects but does not inherit from it.
    class Dialect
      NAMES = %i[postgresql mysql sqlite generic].freeze

      ADAPTER_ANCESTORS = {
        'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter'    => :postgresql,
        'ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter' => :mysql,
        'ActiveRecord::ConnectionAdapters::SQLite3Adapter'       => :sqlite
      }.freeze

      class << self
        def for(klass)
          new(Ransack.options[:dialect] || detect(klass.adapter_class))
        end

        def detect(adapter_class)
          ancestors = adapter_class.ancestors.map(&:name)
          ADAPTER_ANCESTORS.each do |ancestor, dialect|
            return dialect if ancestors.include?(ancestor)
          end
          :generic
        end
      end

      attr_reader :name

      def initialize(name)
        @name = name.to_sym
        unless NAMES.include?(@name)
          raise ArgumentError,
            "Unknown dialect #{name.inspect}; expected one of #{NAMES.map(&:inspect).join(', ')}"
        end
      end

      NAMES.each do |dialect|
        define_method(:"#{dialect}?") { @name == dialect }
      end

      # PostgreSQL has ILIKE, and Arel renders a `matches` that is not
      # case-sensitive as ILIKE there. Elsewhere Ransack lowers both sides.
      def case_insensitive_like?
        postgresql?
      end

      # CHAR_LENGTH counts characters and is the SQL standard spelling; SQLite
      # has no CHAR_LENGTH and its LENGTH already counts characters for text.
      def length_function
        postgresql? || mysql? ? 'CHAR_LENGTH'.freeze : 'LENGTH'.freeze
      end

      def ==(other)
        other.is_a?(Dialect) && other.name == name
      end
      alias :eql? :==

      def hash
        name.hash
      end

      def inspect
        "#<Ransack::ActiveRecord::Dialect #{name}>"
      end
    end
  end
end
