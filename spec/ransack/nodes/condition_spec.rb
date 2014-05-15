require 'spec_helper'

module Ransack
  module Nodes
    describe Condition do

      context 'with multiple values and an _any predicate' do
        subject { Condition.extract(Context.for(Person), 'name_eq_any', Person.first(2).map(&:name)) }

        specify { expect(subject.values.size).to eq(2) }
      end

    end
  end
end