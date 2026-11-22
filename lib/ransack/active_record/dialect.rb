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

      # Whether LIKE against a column with this collation already ignores
      # case, so a case-insensitive predicate need not lower the column.
      #
      # MySQL and MariaDB compare with the column's collation, and the
      # default ones (utf8mb4_0900_ai_ci, utf8mb4_general_ci and the like)
      # are case-insensitive: their names end in `_ci`. Lowering such a
      # column changes no result, and it keeps a prefix LIKE from using the
      # column's index, so a search on `i_start` scans the whole table.
      # A `_bin` or `_cs` column, or one with no collation at all, is still
      # lowered, since there LIKE is case-sensitive.
      #
      # Elsewhere the collation is not consulted: PostgreSQL has ILIKE, and
      # SQLite's LIKE ignores the column's collation.
      def case_insensitive_collation?(collation)
        mysql? && collation.to_s.end_with?('_ci'.freeze)
      end

      # CHAR_LENGTH is the SQL standard spelling and what PostgreSQL and MySQL
      # use; their LENGTH counts bytes on MySQL. SQLite has no CHAR_LENGTH,
      # and neither does Oracle, while both count characters with LENGTH, so
      # the generic dialect keeps LENGTH: it is the spelling the adapters
      # Ransack does not know are most likely to have.
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
