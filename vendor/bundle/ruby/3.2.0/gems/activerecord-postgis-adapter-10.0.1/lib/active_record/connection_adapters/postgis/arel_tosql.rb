# frozen_string_literal: true

module RGeo
  module ActiveRecord
    ##
    # Extend rgeo-activerecord visitors to use PostGIS specific functionality
    module SpatialToPostGISSql
      def visit_in_spatial_context(node, collector)
        # Use ST_GeomFromEWKT for EWKT geometries
        if node.is_a?(String) && node =~ /SRID=[\d+]{0,};/
          collector << "#{st_func('ST_GeomFromEWKT')}(#{quote(node)})"
        else
          super(node, collector)
        end
      end
    end
  end
end
RGeo::ActiveRecord::SpatialToSql.prepend RGeo::ActiveRecord::SpatialToPostGISSql

module Arel  # :nodoc:
  module Visitors  # :nodoc:
    # Different super-class under JRuby JDBC adapter.
    PostGISSuperclass = if defined?(::ArJdbc::PostgreSQL::BindSubstitution)
                          ::ArJdbc::PostgreSQL::BindSubstitution
                        else
                          PostgreSQL
                        end

    class PostGIS < PostGISSuperclass  # :nodoc:
      include RGeo::ActiveRecord::SpatialToSql
    end
  end
end
