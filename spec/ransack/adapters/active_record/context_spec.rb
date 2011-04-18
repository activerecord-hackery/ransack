require 'spec_helper'

module Ransack
  module Adapters
    module ActiveRecord
      describe Context do
        before do
          @c = Context.new(Person)
        end

        it 'contextualizes strings to attributes' do
          attribute = @c.contextualize 'children_children_parent_name'
          attribute.should be_a Arel::Attributes::Attribute
          attribute.name.to_s.should eq 'name'
          attribute.relation.table_alias.should eq 'parents_people'
        end

        it 'builds new associations if not yet built' do
          attribute = @c.contextualize 'children_articles_title'
          attribute.should be_a Arel::Attributes::Attribute
          attribute.name.to_s.should eq 'title'
          attribute.relation.name.should eq 'articles'
          attribute.relation.table_alias.should be_nil
        end

      end
    end
  end
end