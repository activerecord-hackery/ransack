require 'spec_helper'

module Ransack
  describe Configuration do
    it 'yields Ransack on configure' do
      Ransack.configure do |config|
        config.should eq Ransack
      end
    end

    it 'adds predicates' do
      Ransack.configure do |config|
        config.add_predicate :test_predicate
      end

      Ransack.predicates.should have_key 'test_predicate'
      Ransack.predicates.should have_key 'test_predicate_any'
      Ransack.predicates.should have_key 'test_predicate_all'
    end

    it 'avoids creating compound predicates if :compounds => false' do
      Ransack.configure do |config|
        config.add_predicate :test_predicate_without_compound, :compounds => false
      end

      Ransack.predicates.should have_key 'test_predicate_without_compound'
      Ransack.predicates.should_not have_key 'test_predicate_without_compound_any'
      Ransack.predicates.should_not have_key 'test_predicate_without_compound_all'
    end
  end
end