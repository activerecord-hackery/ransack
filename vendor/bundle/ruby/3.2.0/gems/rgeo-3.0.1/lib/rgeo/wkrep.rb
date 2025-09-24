# frozen_string_literal: true

# The WKRep module contains implementations of the OpenGIS well-known
# representations: the WKT (well-known text representation) and the
# WKB (well-known binary representation), as defined in the Simple
# Features Specification, version 1.1. Facilities are provided to
# serialize any geometry into one of these formats, and to parse a
# serialized string back into a geometry. Support is also provided for
# the common extensions to these formats-- notably, the EWKT and EWKB
# formats used by PostGIS.
#
# To serialize a geometry into WKT (well-known text) format, use
# the WKRep::WKTGenerator class.
#
# To serialize a geometry into WKB (well-known binary) format, use
# the WKRep::WKBGenerator class.
#
# To parse a string in WKT (well-known text) format back into a
# geometry object, use the WKRep::WKTParser class.
#
# To parse a byte string in WKB (well-known binary) format back into a
# geometry object, use the WKRep::WKBParser class.

require_relative "wkrep/wkt_parser"
require_relative "wkrep/wkt_generator"
require_relative "wkrep/wkb_parser"
require_relative "wkrep/wkb_generator"
