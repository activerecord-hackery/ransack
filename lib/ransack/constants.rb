module Ransack
  module Constants
    TRUE_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE'].to_set
    FALSE_VALUES = [false, 0, '0', 'f', 'F', 'false', 'FALSE'].to_set

    AREL_PREDICATES = %w(eq not_eq matches does_not_match lt lteq gt gteq in not_in)

    DERIVED_PREDICATES = [
      ['cont', {:arel_predicate => 'matches', :formatter => proc {|v| "%#{escape_wildcards(v)}%"}}],
      ['not_cont', {:arel_predicate => 'does_not_match', :formatter => proc {|v| "%#{escape_wildcards(v)}%"}}],
      ['start', {:arel_predicate => 'matches', :formatter => proc {|v| "#{escape_wildcards(v)}%"}}],
      ['not_start', {:arel_predicate => 'does_not_match', :formatter => proc {|v| "#{escape_wildcards(v)}%"}}],
      ['end', {:arel_predicate => 'matches', :formatter => proc {|v| "%#{escape_wildcards(v)}"}}],
      ['not_end', {:arel_predicate => 'does_not_match', :formatter => proc {|v| "%#{escape_wildcards(v)}"}}],
      ['true', {:arel_predicate => 'eq', :compounds => false, :type => :boolean, :validator => proc {|v| TRUE_VALUES.include?(v)}}],
      ['false', {:arel_predicate => 'eq', :compounds => false, :type => :boolean, :validator => proc {|v| TRUE_VALUES.include?(v)}, :formatter => proc {|v| !v}}],
      ['present', {:arel_predicate => 'not_eq_all', :compounds => false, :type => :boolean, :validator => proc {|v| TRUE_VALUES.include?(v)}, :formatter => proc {|v| [nil, '']}}],
      ['blank', {:arel_predicate => 'eq_any', :compounds => false, :type => :boolean, :validator => proc {|v| TRUE_VALUES.include?(v)}, :formatter => proc {|v| [nil, '']}}],
      ['null', {:arel_predicate => 'eq', :compounds => false, :type => :boolean, :validator => proc {|v| TRUE_VALUES.include?(v)}, :formatter => proc {|v| nil}}],
      ['not_null', {:arel_predicate => 'not_eq', :compounds => false, :type => :boolean, :validator => proc {|v| TRUE_VALUES.include?(v)}, :formatter => proc {|v| nil}}]
    ]

    module_function
    # replace % \ to \% \\
    def escape_wildcards(unescaped)
      unescaped.to_s.gsub(/\\/){ "\\\\" }.gsub(/%/, "\\%")
    end
  end
end
