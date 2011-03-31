require 'spec_helper'

module Ransack
  describe Configuration do
    it 'yields self on configure' do
      Ransack.configure do
        self.should eq Ransack::Configuration
      end
    end
  end
end