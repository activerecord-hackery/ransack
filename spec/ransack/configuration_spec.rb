require 'spec_helper'

module Ransack
  describe Configuration do
    it 'yields Ransack on configure' do
      Ransack.configure do |config|
        config.should eq Ransack
      end
    end
  end
end