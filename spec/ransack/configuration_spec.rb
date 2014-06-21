require 'spec_helper'

module Ransack
  describe Configuration do
    it 'yields Ransack on configure' do
      Ransack.configure do |config|
        expect(config).to eq Ransack
      end
    end

    it 'adds predicates' do
      Ransack.configure do |config|
        config.add_predicate :test_predicate
      end

      expect(Ransack.predicates).to have_key 'test_predicate'
      expect(Ransack.predicates).to have_key 'test_predicate_any'
      expect(Ransack.predicates).to have_key 'test_predicate_all'
    end

    it 'avoids creating compound predicates if compounds: false' do
      Ransack.configure do |config|
        config.add_predicate(
          :test_predicate_without_compound,
          :compounds => false
          )
      end
      expect(Ransack.predicates)
      .to have_key 'test_predicate_without_compound'
      expect(Ransack.predicates)
      .not_to have_key 'test_predicate_without_compound_any'
      expect(Ransack.predicates)
      .not_to have_key 'test_predicate_without_compound_all'
    end

    it 'should have default value for search key' do
      expect(Ransack.options[:search_key]).to eq :q
    end

    it 'changes default search key parameter' do
      # store original state so we can restore it later
      before = Ransack.options.clone

      Ransack.configure do |config|
        config.search_key = :query
      end

      expect(Ransack.options[:search_key]).to eq :query

      # restore original state so we don't break other tests
      Ransack.options = before
    end

    it 'adds predicates that take arrays, overriding compounds' do
      Ransack.configure do |config|
        config.add_predicate(
          :test_array_predicate,
          :wants_array => true,
          :compounds => true
          )
      end

      expect(Ransack.predicates['test_array_predicate'].wants_array).to eq true
      expect(Ransack.predicates).not_to have_key 'test_array_predicate_any'
      expect(Ransack.predicates).not_to have_key 'test_array_predicate_all'
    end
  end
end
