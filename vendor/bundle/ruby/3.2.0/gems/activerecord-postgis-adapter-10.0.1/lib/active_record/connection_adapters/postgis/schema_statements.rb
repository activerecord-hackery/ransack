# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module SchemaStatements
        # override
        # https://github.com/rails/rails/blob/7-0-stable/activerecord/lib/active_record/connection_adapters/postgresql/schema_statements.rb#L662
        # Create a SpatialColumn instead of a PostgreSQL::Column
        def new_column_from_field(table_name, field, _definitions)
          column_name, type, default, notnull, oid, fmod, collation, comment, identity, attgenerated = field
          type_metadata = fetch_type_metadata(column_name, type, oid.to_i, fmod.to_i)
          default_value = extract_value_from_default(default)

          if attgenerated.present?
            default_function = default
          else
            default_function = extract_default_function(default_value, default)
          end

          if (match = default_function&.match(/\Anextval\('"?(?<sequence_name>.+_(?<suffix>seq\d*))"?'::regclass\)\z/))
            serial = sequence_name_from_parts(table_name, column_name, match[:suffix]) == match[:sequence_name]
          end

          # {:dimension=>2, :has_m=>false, :has_z=>false, :name=>"latlon", :srid=>0, :type=>"GEOMETRY"}
          spatial = spatial_column_info(table_name).get(column_name, type_metadata.sql_type)

          SpatialColumn.new(
            column_name,
            default_value,
            type_metadata,
            !notnull,
            default_function,
            collation: collation,
            comment: comment.presence,
            serial: serial,
            generated: attgenerated,
            identity: identity.presence,
            spatial: spatial
          )
        end

        # override
        def create_table_definition(*args, **kwargs)
          PostGIS::TableDefinition.new(self, *args, **kwargs)
        end

        # memoize hash of column infos for tables
        def spatial_column_info(table_name)
          @spatial_column_info ||= {}
          @spatial_column_info[table_name.to_sym] ||= SpatialColumnInfo.new(self, table_name.to_s)
        end
      end
    end
  end
end
