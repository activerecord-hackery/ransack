require 'spec_helper'

module Ransack
  # A search checks each name against the allowlists several times over. The
  # model is asked for each list once per search, and asked again when the
  # auth object or the permitted flag the lists depend on changes.
  describe 'allowlists within a search' do
    let(:context) { Person.ransack.context }

    it 'asks the model for each list once, however many names are checked' do
      expect(Person).to receive(:ransackable_attributes).once.and_call_original
      Person.ransack(name_cont: 'a', email_eq: 'b', name_or_email_start: 'c', s: 'name asc')
    end

    it 'asks again when the auth object changes' do
      expect(context.ransackable_attribute?('only_admin', Person)).to be false

      context.auth_object = :admin
      expect(context.ransackable_attribute?('only_admin', Person)).to be true

      context.auth_object = nil
      expect(context.ransackable_attribute?('only_admin', Person)).to be false
    end

    it 'asks again when the permitted flag changes' do
      expect(Person).to receive(:ransackable_attributes).twice.and_call_original
      context.ransackable_attribute?('name', Person)
      context.permitted = true
      context.ransackable_attribute?('name', Person)
    end

    it 'resolves the aliases in a key once per search' do
      expect(context).to receive(:resolve_aliases_uncached).once.and_call_original
      3.times { expect(context.resolve_aliases('term_or_daddy')).to eq 'name_or_email_or_parent_name' }
    end

    it 'returns a frozen name, so the kept copy cannot be changed through it' do
      expect(context.resolve_aliases('term')).to be_frozen
    end

    it 'resolves aliases again when the auth object changes' do
      context.resolve_aliases('term')
      context.auth_object = :admin
      expect(context).to receive(:resolve_aliases_uncached).once.and_call_original
      context.resolve_aliases('term')
    end

    it 'answers attribute_method? again when the auth object changes' do
      expect(context.attribute_method?('only_admin')).to be false
      expect(context.attribute_method?('children_only_admin')).to be false

      context.auth_object = :admin
      expect(context.attribute_method?('only_admin')).to be true
      expect(context.attribute_method?('children_only_admin')).to be true
    end

    it 'checks each top-level key once while building' do
      expect_any_instance_of(Nodes::Grouping)
        .to receive(:attribute_method?).with('name_cont').once.and_call_original
      expect(Person.ransack(name_cont: 'a').result.to_sql).to include 'LIKE'
    end

    it 'matches symbol and string allowlists alike' do
      allow(Person).to receive(:ransackable_attributes).and_return(%i[name])
      expect(context.ransackable_attribute?('name', Person)).to be true
      expect(context.ransackable_attribute?(:name, Person)).to be true
      expect(context.ransackable_attribute?('email', Person)).to be false
    end
  end
end
