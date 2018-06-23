require 'spec_helper'

module Polyamorous
  describe JoinAssociation do

    join_base, join_association_args, polymorphic =
      if ActiveRecord::VERSION::STRING >= '4.1'
        [:join_root, 'parent.children', 'reflection.options[:polymorphic]']
      else
        [:join_base, 'join_dependency, parent', 'options[:polymorphic]']
      end

    let(:join_dependency) { new_join_dependency Note, {} }
    let(:reflection) { Note.reflect_on_association(:notable) }
    let(:parent) { join_dependency.send(join_base) }
    let(:join_association) {
      eval("new_join_association(reflection, #{join_association_args}, Article)")
    }

    subject {
      join_dependency.build_join_association_respecting_polymorphism(
        reflection, parent, Person
      )
    }

    it 'respects polymorphism on equality test' do
      expect(subject).to eq(
        join_dependency.build_join_association_respecting_polymorphism(
          reflection, parent, Person
        )
      )
      expect(subject).not_to eq(
        join_dependency.build_join_association_respecting_polymorphism(
          reflection, parent, Article
        )
      )
    end

    it 'leaves the orginal reflection intact for thread safety' do
      reflection.instance_variable_set(:@klass, Article)
      join_association
      .swapping_reflection_klass(reflection, Person) do |new_reflection|
        expect(new_reflection.options).not_to equal reflection.options
        expect(new_reflection.options).not_to have_key(:polymorphic)
        expect(new_reflection.klass).to eq(Person)
        expect(reflection.klass).to eq(Article)
      end
    end

    it 'sets the polymorphic option to true after initializing' do
      expect(join_association.instance_eval(polymorphic)).to be true
    end
  end
end
