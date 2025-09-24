module Arel
  module Predications
    def in_or_blank(other)
      # Create an IN predicate for the non-null values
      in_predicate = self.in(other)
      
      # Create blank/null predicate (IS NULL OR = '')
      null_predicate = self.eq(nil)
      empty_predicate = self.eq('')
      blank_predicate = null_predicate.or(empty_predicate)
      
      # Combine with OR
      in_predicate.or(blank_predicate)
    end
  end
end