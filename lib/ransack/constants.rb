module Ransack
  module Constants
    TRUE_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE'].to_set
    FALSE_VALUES = [false, 0, '0', 'f', 'F', 'false', 'FALSE'].to_set
    BOOLEAN_VALUES = TRUE_VALUES + FALSE_VALUES

    AREL_PREDICATES = %w(eq not_eq matches does_not_match lt lteq gt gteq in not_in)

    DERIVED_PREDICATES = [
      ['cont', {
        :arel_predicate => 'matches',
        :formatter => proc { |v| "%#{escape_wildcards(v)}%" }
        }
      ],
      ['i_cont', {
        :arel_predicate => 'i_matches',
        :formatter => proc { |v| "%#{escape_wildcards(v)}%" }
      }
      ],
      ['not_cont', {
        :arel_predicate => 'does_not_match',
        :formatter => proc { |v| "%#{escape_wildcards(v)}%" }
        }
      ],
      ['i_not_cont', {
        :arel_predicate => 'i_does_not_match',
        :formatter => proc { |v| "%#{escape_wildcards(v)}%" }
      }
      ],
      ['start', {
        :arel_predicate => 'matches',
        :formatter => proc { |v| "#{escape_wildcards(v)}%" }
        }
      ],
      ['not_start', {
        :arel_predicate => 'does_not_match',
        :formatter => proc { |v| "#{escape_wildcards(v)}%" }
        }
      ],
      ['end', {
        :arel_predicate => 'matches',
        :formatter => proc { |v| "%#{escape_wildcards(v)}" }
        }
      ],
      ['not_end', {
        :arel_predicate => 'does_not_match',
        :formatter => proc { |v| "%#{escape_wildcards(v)}" }
        }
      ],
      ['true', {
        :arel_predicate => proc { |v| v ? 'eq' : 'not_eq' },
        :compounds => false,
        :type => :boolean,
        :validator => proc { |v| BOOLEAN_VALUES.include?(v) },
        :formatter => proc { |v| true }
        }
      ],
      ['not_true', {
        :arel_predicate => proc { |v| v ? 'not_eq' : 'eq' },
        :compounds => false,
        :type => :boolean,
        :validator => proc { |v| BOOLEAN_VALUES.include?(v) },
        :formatter => proc { |v| true }
        }
      ],
      ['false', {
        :arel_predicate => proc { |v| v ? 'eq' : 'not_eq' },
        :compounds => false,
        :type => :boolean,
        :validator => proc { |v| BOOLEAN_VALUES.include?(v) },
        :formatter => proc { |v| false }
        }
      ],
      ['not_false', {
        :arel_predicate => proc { |v| v ? 'not_eq' : 'eq' },
        :compounds => false,
        :type => :boolean,
        :validator => proc { |v| BOOLEAN_VALUES.include?(v) },
        :formatter => proc { |v| false }
        }
      ],
      ['present', {
        :arel_predicate => proc { |v| v ? 'not_eq_all' : 'eq_any' },
        :compounds => false,
        :type => :boolean,
        :validator => proc { |v| BOOLEAN_VALUES.include?(v) },
        :formatter => proc { |v| [nil, ''] }
        }
      ],
      ['blank', {
        :arel_predicate => proc { |v| v ? 'eq_any' : 'not_eq_all' },
        :compounds => false,
        :type => :boolean,
        :validator => proc { |v| BOOLEAN_VALUES.include?(v) },
        :formatter => proc { |v| [nil, ''] }
        }
      ],
      ['null', {
        :arel_predicate => proc { |v| v ? 'eq' : 'not_eq' },
        :compounds => false,
        :type => :boolean,
        :validator => proc { |v| BOOLEAN_VALUES.include?(v)},
        :formatter => proc { |v| nil }
        }
      ],
      ['not_null', {
        :arel_predicate => proc { |v| v ? 'not_eq' : 'eq' },
        :compounds => false,
        :type => :boolean,
        :validator => proc { |v| BOOLEAN_VALUES.include?(v) },
        :formatter => proc { |v| nil } }
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
