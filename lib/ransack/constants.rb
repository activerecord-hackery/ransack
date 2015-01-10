module Ransack
  module Constants
    ASC                 = 'asc'.freeze
    DESC                = 'desc'.freeze
    ASC_DESC            = [ASC, DESC].freeze

    ASC_ARROW           = '&#9650;'.freeze
    DESC_ARROW          = '&#9660;'.freeze

    OR                  = 'or'.freeze
    AND                 = 'and'.freeze
    SPACED_AND          = ' AND '.freeze

    SORT                = 'sort'.freeze
    SORT_LINK           = 'sort_link'.freeze
    SORT_DIRECTION      = 'sort_direction'.freeze

    CAP_SEARCH          = 'Search'.freeze
    SEARCH              = 'search'.freeze
    SEARCHES            = 'searches'.freeze

    ATTRIBUTE           = 'attribute'.freeze
    ATTRIBUTES          = 'attributes'.freeze
    COMBINATOR          = 'combinator'.freeze

    SPACE               = ' '.freeze
    COMMA_SPACE         = ', '.freeze
    COLON_SPACE         = ': '.freeze
    TWO_COLONS          = '::'.freeze
    UNDERSCORE          = '_'.freeze
    LEFT_PARENTHESIS    = '('.freeze
    Q                   = 'q'.freeze
    I                   = 'i'.freeze
    NON_BREAKING_SPACE  = '&nbsp;'.freeze
    DOT_ASTERIX         = '.*'.freeze
    EMPTY               = ''.freeze

    STRING_JOIN         = 'string_join'.freeze
    ASSOCIATION_JOIN    = 'association_join'.freeze
    STASHED_JOIN        = 'stashed_join'.freeze
    JOIN_NODE           = 'join_node'.freeze

    TRUE_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE'].to_set
    FALSE_VALUES = [false, 0, '0', 'f', 'F', 'false', 'FALSE'].to_set
    BOOLEAN_VALUES = (TRUE_VALUES + FALSE_VALUES).freeze

    S_SORTS             = %w(s sorts).freeze
    AND_OR              = %w(and or).freeze
    IN_NOT_IN           = %w(in not_in).freeze
    SUFFIXES            = %w(_any _all).freeze
    AREL_PREDICATES     = %w(
      eq not_eq matches does_not_match lt lteq gt gteq in not_in
    ).freeze
    A_S_I               = %w(a s i).freeze

    EQ                  = 'eq'.freeze
    NOT_EQ              = 'not_eq'.freeze
    EQ_ANY              = 'eq_any'.freeze
    NOT_EQ_ALL          = 'not_eq_all'.freeze
    CONT                = 'cont'.freeze

    RAILS_4_1           = '4.1'.freeze

    RANSACK_SLASH_SEARCHES = 'ransack/searches'.freeze
    RANSACK_SLASH_SEARCHES_SLASH_SEARCH = 'ransack/searches/search'.freeze

    DERIVED_PREDICATES = [
      ['cont', {
        arel_predicate: 'matches',
        formatter: proc { |v| "%#{escape_wildcards(v)}%" }
        }
      ],
      ['not_cont', {
        arel_predicate: 'does_not_match',
        formatter: proc { |v| "%#{escape_wildcards(v)}%" }
        }
      ],
      ['start', {
        arel_predicate: 'matches',
        formatter: proc { |v| "#{escape_wildcards(v)}%" }
        }
      ],
      ['not_start', {
        arel_predicate: 'does_not_match',
        formatter: proc { |v| "#{escape_wildcards(v)}%" }
        }
      ],
      ['end', {
        arel_predicate: 'matches',
        formatter: proc { |v| "%#{escape_wildcards(v)}" }
        }
      ],
      ['not_end', {
        arel_predicate: 'does_not_match',
        formatter: proc { |v| "%#{escape_wildcards(v)}" }
        }
      ],
      ['true', {
        arel_predicate: 'eq',
        compounds: false,
        type: :boolean,
        validator: proc { |v| TRUE_VALUES.include?(v) }
        }
      ],
      ['false', {
        arel_predicate: 'eq',
        compounds: false,
        type: :boolean,
        validator: proc { |v| TRUE_VALUES.include?(v) },
        formatter: proc { |v| !v }
        }
      ],
      ['present', {
        arel_predicate: 'not_eq_all',
        compounds: false,
        type: :boolean,
        validator: proc { |v| TRUE_VALUES.include?(v) },
        formatter: proc { |v| [nil, ''] }
        }
      ],
      ['blank', {
        arel_predicate: 'eq_any',
        compounds: false,
        type: :boolean,
        validator: proc { |v| TRUE_VALUES.include?(v) },
        formatter: proc { |v| [nil, ''] }
        }
      ],
      ['null', {
        arel_predicate: 'eq',
        compounds: false,
        type: :boolean,
        validator: proc { |v| TRUE_VALUES.include?(v)},
        formatter: proc { |v| nil }
        }
      ],
      ['not_null', {
        arel_predicate: 'not_eq',
        compounds: false,
        type: :boolean,
        validator: proc { |v| TRUE_VALUES.include?(v) },
        formatter: proc { |v| nil } }
      ]
    ]

    module_function
    # replace % \ to \% \\
    def escape_wildcards(unescaped)
      case ActiveRecord::Base.connection.adapter_name
      when "Mysql2", "PostgreSQL"
        # Necessary for PostgreSQL and MySQL
        unescaped.to_s.gsub(/([\\|\%|.])/, '\\\\\\1')
      else
        unescaped
      end
    end

  end
end
