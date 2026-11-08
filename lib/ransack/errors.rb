module Ransack
  # Raised for a search that cannot be built from its params: an unknown
  # attribute, predicate, combinator or sort under a strict search, or params
  # of the wrong shape (a string where a hash of conditions belongs) under any
  # search. Search params usually come from the request, so this is the error
  # to rescue to turn a bad search into a 400 rather than a 500. It is an
  # ArgumentError, so code that rescues ArgumentError still catches it.
  class InvalidSearchError < ArgumentError; end

  # Raised internally when a name does not resolve to an association. The
  # form builder rescues it; a search never lets it escape.
  class UntraversableAssociationError < StandardError; end
end
