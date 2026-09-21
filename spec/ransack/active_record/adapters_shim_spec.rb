require 'spec_helper'

module Ransack
  describe 'the Ransack::Adapters::ActiveRecord compatibility shim' do
    before do
      Adapters.send(:remove_const, :ActiveRecord) if Adapters.const_defined?(:ActiveRecord, false)
    end

    it 'resolves the old constant to Ransack::ActiveRecord with a deprecation warning' do
      resolved = nil
      expect { resolved = Adapters::ActiveRecord }
        .to output(/Ransack::Adapters::ActiveRecord is deprecated/).to_stderr
      expect(resolved).to equal Ransack::ActiveRecord
      expect(Adapters::ActiveRecord::Base).to equal Ransack::ActiveRecord::Base
      expect(Adapters::ActiveRecord::Context).to equal Ransack::ActiveRecord::Context
    end

    it 'warns once, when the constant is first resolved' do
      Adapters::ActiveRecord rescue nil
      expect { Adapters::ActiveRecord }.not_to output.to_stderr
    end

    it 'leaves other missing constants alone' do
      expect { Adapters::Mongoid }.to raise_error(NameError)
    end
  end
end
