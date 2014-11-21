module Ransack
  module Constants
    DERIVED_PREDICATES = [
      [CONT, {
        :arel_predicate => 'matches',
        :formatter => proc { |v| "#{escape_regex(v)}" }
        }
      ],
      ['not_cont', {
        :arel_predicate => 'does_not_match',
        :formatter => proc { |v| "#{escape_regex(v)}" }
        }
      ],
      ['start', {
        :arel_predicate => 'matches',
        :formatter => proc { |v| "\\A#{escape_regex(v)}" }
        }
      ],
      ['not_start', {
        :arel_predicate => 'does_not_match',
        :formatter => proc { |v| "\\A#{escape_regex(v)}" }
        }
      ],
      ['end', {
        :arel_predicate => 'matches',
        :formatter => proc { |v| "#{escape_regex(v)}\\Z" }
        }
      ],
      ['not_end', {
        :arel_predicate => 'does_not_match',
        :formatter => proc { |v| "#{escape_regex(v)}\\Z" }
        }
      ],
      ['true', {
        :arel_predicate => 'eq',
        :compounds => false,
        :type => :boolean,
        :validator => proc { |v| TRUE_VALUES.include?(v) }
        }
      ],
      ['false', {
        :arel_predicate => 'eq',
        :compounds => false,
        :type => :boolean,
        :validator => proc { |v| TRUE_VALUES.include?(v) },
        :formatter => proc { |v| !v }
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
    # does nothing
    def escape_regex(unescaped)
      Regexp.escape(unescaped)
    end
  end
end
