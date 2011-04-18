require 'active_record'

module Ransack
  module Adapters
    module ActiveRecord
      module JoinDependency

        # Yes, I'm using alias_method_chain here. No, I don't feel too
        # bad about it. JoinDependency, or, to call it by its full proper
        # name, ::ActiveRecord::Associations::JoinDependency, is one of the
        # most "for internal use only" chunks of ActiveRecord.
        def self.included(base)
          base.class_eval do
            alias_method_chain :graft, :ransack
          end
        end

        def graft_with_ransack(*associations)
          associations.each do |association|
            join_associations.detect {|a| association == a} ||
              build_polymorphic(association.reflection.name, association.find_parent_in(self) || join_base, association.join_type, association.reflection.klass)
          end
          self
        end

        # Should only be called by Ransack, and only with a single association name
        def build_polymorphic(association, parent = nil, join_type = Arel::OuterJoin, klass = nil)
          parent ||= joins.last
          reflection = parent.reflections[association] or
            raise ::ActiveRecord::ConfigurationError, "Association named '#{ association }' was not found; perhaps you misspelled it?"
          unless join_association = find_join_association_respecting_polymorphism(reflection, parent, klass)
            @reflections << reflection
            join_association = build_join_association_respecting_polymorphism(reflection, parent, klass)
            join_association.join_type = join_type
            @joins << join_association
            cache_joined_association(join_association)
          end

          join_association
        end

        def find_join_association_respecting_polymorphism(reflection, parent, klass)
          if association = find_join_association(reflection, parent)
            unless reflection.options[:polymorphic]
              association
            else
              association if association.active_record == klass
            end
          end
        end

        def build_join_association_respecting_polymorphism(reflection, parent, klass = nil)
          if reflection.options[:polymorphic] && klass
            JoinAssociation.new(reflection, self, parent, klass)
          else
            JoinAssociation.new(reflection, self, parent)
          end
        end

      end
    end
  end
end