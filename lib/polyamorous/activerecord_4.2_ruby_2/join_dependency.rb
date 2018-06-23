# active_record_4.2_ruby_2/join_dependency.rb
require 'polyamorous/activerecord_5.0_ruby_2/join_dependency'

module Polyamorous
  module JoinDependencyExtensions
    # Replaces ActiveRecord::Associations::JoinDependency#join_constraints
    # to call #make_polyamorous_inner_joins instead of #make_inner_joins.
    #
    def join_constraints(outer_joins)
      joins = join_root.children.flat_map { |child|
        make_polyamorous_inner_joins join_root, child
      }
      joins.concat outer_joins.flat_map { |oj|
        if join_root.match? oj.join_root
          walk(join_root, oj.join_root)
        else
          oj.join_root.children.flat_map { |child|
            make_outer_joins(oj.join_root, child)
          }
        end
      }
    end
  end
end
