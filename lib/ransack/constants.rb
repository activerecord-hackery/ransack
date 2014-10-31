module Ransack
  module Constants
    TRUE_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE'].to_set
    FALSE_VALUES = [false, 0, '0', 'f', 'F', 'false', 'FALSE'].to_set
    BOOLEAN_VALUES = TRUE_VALUES + FALSE_VALUES

    S_SORTS             = %w(s sorts).freeze
    ASC_DESC            = %w(asc desc).freeze
    AND_OR              = %w(and or).freeze
    IN_NOT_IN           = %w(in not_in).freeze
    SUFFIXES            = %w(_any _all).freeze
    AREL_PREDICATES     = %w(
      eq not_eq matches does_not_match lt lteq gt gteq in not_in
    ).freeze

    EQ                  = 'eq'.freeze
    NOT_EQ              = 'not_eq'.freeze
    EQ_ANY              = 'eq_any'.freeze
    NOT_EQ_ALL          = 'not_eq_all'.freeze

  end
end
