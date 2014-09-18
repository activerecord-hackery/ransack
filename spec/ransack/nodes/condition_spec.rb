require 'spec_helper'

module Ransack
  module Nodes
    describe Condition do

      context 'with multiple values and an _any predicate' do
        subject {
          Condition.extract(
            Context.for(Person), 'name_eq_any', Person.first(2).map(&:name)
          )
        }

        specify { expect(subject.values.size).to eq(2) }
      end

      context 'with an invalid predicate' do
        subject {
          Condition.extract(
            Context.for(Person), 'name_invalid', Person.first.name
          )
        }

        context "when ignore_unknown_conditions is false" do
          before do
            Ransack.configure { |config| config.ignore_unknown_conditions = false }
          end

          specify { expect { subject }.to raise_error ArgumentError }
        end

        context "when ignore_unknown_conditions is true" do
          before do
            Ransack.configure { |config| config.ignore_unknown_conditions = true }
          end

          specify { subject.should be_nil }
        end
      end
    end
  end
end
