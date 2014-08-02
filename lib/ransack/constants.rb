module Ransack
  module Constants
    TRUE_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE'].to_set
    FALSE_VALUES = [false, 0, '0', 'f', 'F', 'false', 'FALSE'].to_set
    BOOLEAN_VALUES = TRUE_VALUES + FALSE_VALUES

    AREL_PREDICATES = %w(eq not_eq matches does_not_match lt lteq gt gteq in not_in)

  end
end
