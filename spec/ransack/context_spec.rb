require 'spec_helper'

module Ransack
  describe Context do
    # A context registered for another ORM subclasses Ransack::Context and
    # implements what it needs. Sorts and negative conditions call the join
    # hooks, so the base class answers them.
    describe 'the join hooks' do
      let(:context) { Class.new(Context).allocate }

      it 'answers lock_association without an override' do
        expect { context.lock_association(:association) }.not_to raise_error
      end

      it 'answers lock_ancestors_of without an override' do
        expect { context.lock_ancestors_of(:association) }.not_to raise_error
      end
    end
  end
end
