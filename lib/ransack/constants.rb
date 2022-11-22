module Ransack
  module Constants
    OR                  = 'or'.freeze
    AND                 = 'and'.freeze

    CAP_SEARCH          = 'Search'.freeze
    SEARCH              = 'search'.freeze
    SEARCHES            = 'searches'.freeze

    ATTRIBUTE           = 'attribute'.freeze
    ATTRIBUTES          = 'attributes'.freeze
    COMBINATOR          = 'combinator'.freeze

    TWO_COLONS          = '::'.freeze
    UNDERSCORE          = '_'.freeze
    LEFT_PARENTHESIS    = '('.freeze
    Q                   = 'q'.freeze
    I                   = 'i'.freeze
    DOT_ASTERIX         = '.*'.freeze

    STRING_JOIN         = 'string_join'.freeze
    ASSOCIATION_JOIN    = 'association_join'.freeze
    STASHED_JOIN        = 'stashed_join'.freeze
    JOIN_NODE           = 'join_node'.freeze

    TRUE_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE'].to_set
    FALSE_VALUES = [false, 0, '0', 'f', 'F', 'false', 'FALSE'].to_set
    BOOLEAN_VALUES = (TRUE_VALUES + FALSE_VALUES).freeze

    AND_OR              = ['and'.freeze, 'or'.freeze].freeze
    IN_NOT_IN           = ['in'.freeze, 'not_in'.freeze].freeze
    SUFFIXES            = ['_any'.freeze, '_all'.freeze].freeze
    AREL_PREDICATES     = [
      'eq'.freeze, 'not_eq'.freeze,
      'matches'.freeze, 'does_not_match'.freeze,
      'lt'.freeze, 'lteq'.freeze,
      'gt'.freeze, 'gteq'.freeze,
      'in'.freeze, 'not_in'.freeze
    ].freeze
    A_S_I               = ['a'.freeze, 's'.freeze, 'i'.freeze].freeze

    EQ                  = 'eq'.freeze
    NOT_EQ              = 'not_eq'.freeze
    EQ_ANY              = 'eq_any'.freeze
    NOT_EQ_ALL          = 'not_eq_all'.freeze
    CONT                = 'cont'.freeze

    RANSACK_SLASH_SEARCHES = 'ransack/searches'.freeze
    RANSACK_SLASH_SEARCHES_SLASH_SEARCH = 'ransack/searches/search'.freeze

    DISTINCT = 'DISTINCT '.freeze

    DERIVED_PREDICATES = [
      [CONT, {
        arel_predicate: 'matches'.freeze,
        formatter: proc { |v| "%#{escape_wildcards(v)}%" }
        }
      ],
      ['not_cont'.freeze, {
        arel_predicate: 'does_not_match'.freeze,
        formatter: proc { |v| "%#{escape_wildcards(v)}%" }
        }
      ],
      ['i_cont'.freeze, {
        arel_predicate: 'matches'.freeze,
        formatter: proc { |v| "%#{escape_wildcards(v.downcase)}%" },
        case_insensitive: true
        }
      ],
      ['not_i_cont'.freeze, {
        arel_predicate: 'does_not_match'.freeze,
        formatter: proc { |v| "%#{escape_wildcards(v.downcase)}%" },
        case_insensitive: true
        }
      ],
      ['start'.freeze, {
        arel_predicate: 'matches'.freeze,
        formatter: proc { |v| "#{escape_wildcards(v)}%" }
        }
      ],
      ['not_start'.freeze, {
        arel_predicate: 'does_not_match'.freeze,
        formatter: proc { |v| "#{escape_wildcards(v)}%" }
        }
      ],
      ['end'.freeze, {
        arel_predicate: 'matches'.freeze,
        formatter: proc { |v| "%#{escape_wildcards(v)}" }
        }
      ],
      ['not_end'.freeze, {
        arel_predicate: 'does_not_match'.freeze,
        formatter: proc { |v| "%#{escape_wildcards(v)}" }
        }
      ],
      ['true'.freeze, {
        arel_predicate: proc { |v| v ? EQ : NOT_EQ },
        compounds: false,
        type: :boolean,
        validator: proc { |v| BOOLEAN_VALUES.include?(v) },
        formatter: proc { |v| true }
        }
      ],
      ['not_true'.freeze, {
        arel_predicate: proc { |v| v ? NOT_EQ : EQ },
        compounds: false,
        type: :boolean,
        validator: proc { |v| BOOLEAN_VALUES.include?(v) },
        formatter: proc { |v| true }
        }
      ],
      ['false'.freeze, {
        arel_predicate: proc { |v| v ? EQ : NOT_EQ },
        compounds: false,
        type: :boolean,
        validator: proc { |v| BOOLEAN_VALUES.include?(v) },
        formatter: proc { |v| false }
        }
      ],
      ['not_false'.freeze, {
        arel_predicate: proc { |v| v ? NOT_EQ : EQ },
        compounds: false,
        type: :boolean,
        validator: proc { |v| BOOLEAN_VALUES.include?(v) },
        formatter: proc { |v| false }
        }
      ],
      ['present'.freeze, {
        arel_predicate: proc { |v| v ? NOT_EQ_ALL : EQ_ANY },
        compounds: false,
        type: :boolean,
        validator: proc { |v| BOOLEAN_VALUES.include?(v) },
        formatter: proc { |v| [nil, ''.freeze].freeze }
        }
      ],
      ['blank'.freeze, {
        arel_predicate: proc { |v| v ? EQ_ANY : NOT_EQ_ALL },
        compounds: false,
        type: :boolean,
        validator: proc { |v| BOOLEAN_VALUES.include?(v) },
        formatter: proc { |v| [nil, ''.freeze].freeze }
        }
      ],
      ['null'.freeze, {
        arel_predicate: proc { |v| v ? EQ : NOT_EQ },
        compounds: false,
        type: :boolean,
        validator: proc { |v| BOOLEAN_VALUES.include?(v) },
        formatter: proc { |v| nil }
        }
      ],
      ['not_null'.freeze, {
        arel_predicate: proc { |v| v ? NOT_EQ : EQ },
        compounds: false,
        type: :boolean,
        validator: proc { |v| BOOLEAN_VALUES.include?(v) },
        formatter: proc { |v| nil } }
      ]
    ].freeze

  module_function
    # replace % \ to \% \\
    def escape_wildcards(unescaped)
      case ActiveRecord::Base.connection.adapter_name
      when "Mysql2".freeze
        # Necessary for MySQL
        unescaped.to_s.gsub(/([\\%_])/, '\\\\\\1')
      when "PostgreSQL".freeze
        # Necessary for PostgreSQL
        unescaped.to_s.gsub(/([\\%_.])/, '\\\\\\1')
      else
        unescaped
      end
    end
  end
end
