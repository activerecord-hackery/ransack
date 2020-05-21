module Ransack
  module Nodes
    class Condition

      def arel_predicate
        attributes.map { |attribute|
          association = attribute.parent
          has_reflection = association.respond_to?(:reflection)
          is_base_join = !has_reflection || context.klass == association.reflection.active_record
          primary_key = is_base_join ? context.primary_key : Ransack::Context.for(association.reflection.active_record).primary_key
          if negative? && attribute.associated_collection?
            query = context.build_correlated_subquery(association)
            if Ransack::Configuration.options[:remove_association_no_negative_assoc]
              context.remove_association(association)
            end
            if self.predicate_name == 'not_null' && self.value
              query.where(format_predicate(attribute))
              Arel::Nodes::In.new(primary_key, Arel.sql(query.to_sql))
            else
              query.where(format_predicate(attribute).not)
              Arel::Nodes::NotIn.new(primary_key, Arel.sql(query.to_sql))
            end
          else
            format_predicate(attribute)
          end
        }.reduce(combinator_method)
      end

      private

        def combinator_method
          combinator === Constants::OR ? :or : :and
        end

        def format_predicate(attribute)
          arel_pred = arel_predicate_for_attribute(attribute)
          arel_values = formatted_values_for_attribute(attribute)
          predicate = attr_value_for_attribute(attribute).public_send(arel_pred, arel_values)

          if in_predicate?(predicate)
            predicate.right = predicate.right.map do |pr|
              casted_array?(pr) ? format_values_for(pr) : pr
            end
          end

          predicate
        end

        def in_predicate?(predicate)
          return unless defined?(Arel::Nodes::Casted)
          predicate.class == Arel::Nodes::In || predicate.class == Arel::Nodes::NotIn
        end

        def casted_array?(predicate)
          predicate.respond_to?(:val) && predicate.val.is_a?(Array)
        end

        def format_values_for(predicate)
          predicate.val.map do |value|
            value.is_a?(String) ? Arel::Nodes.build_quoted(value) : value
          end
        end

    end
  end
end
