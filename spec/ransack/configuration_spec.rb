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

    it 'should have default value for search key' do
      Ransack.options[:search_key].should eq :q
    end

    it 'changes default search key parameter' do
      # store original state so we can restore it later
      before = Ransack.options.clone

      Ransack.configure do |config|
        config.search_key = :query
      end

      Ransack.options[:search_key].should eq :query

      # restore original state so we don't break other tests
      Ransack.options = before
    end

    it 'adds predicates that take arrays, overriding compounds' do
      Ransack.configure do |config|
        config.add_predicate :test_array_predicate, :wants_array => true, :compounds => true
      end

      Ransack.predicates['test_array_predicate'].wants_array.should eq true
      Ransack.predicates.should_not have_key 'test_array_predicate_any'
      Ransack.predicates.should_not have_key 'test_array_predicate_all'
    end
  end
end