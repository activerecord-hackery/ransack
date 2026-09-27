require 'spec_helper'

module Ransack
  # Strong parameters as the authorization boundary for a model that defines
  # no allowlist of its own (#1403). `Unlisted` inherits from
  # `ActiveRecord::Base` directly because the spec schema's
  # `ApplicationRecord` gives every other model a list. `Person` has lists:
  # it allows neither `only_sort` for searching nor `only_search` for
  # sorting, and defines no `ransackable_scopes`.
  class Unlisted < ::ActiveRecord::Base
    self.table_name = 'people'
    has_many :articles, foreign_key: :person_id

    scope :active, -> { where(awesome: true) }
  end

  # A model with `ransackable_attributes` and nothing else.
  class Listed < ::ActiveRecord::Base
    self.table_name = 'people'

    def self.ransackable_attributes(auth_object = nil)
      %w[name]
    end
  end

  describe 'strong parameters' do
    def permitted(hash)
      ::ActionController::Parameters.new(hash).permit!
    end

    def unpermitted(hash)
      ::ActionController::Parameters.new(hash)
    end

    let(:only_sort) { "#{quote_table_name("people")}.#{quote_column_name("only_sort")}" }

    context 'a model with no allowlist' do
      it 'lets permitted params search any column that exists' do
        sql = Unlisted.ransack(permitted(only_sort_eq: 'x')).result.to_sql
        expect(sql).to match(/#{only_sort} = 'x'/)
      end

      it 'lets permitted params sort by any column that exists' do
        sql = Unlisted.ransack(permitted(s: 'only_search asc')).result.to_sql
        expect(sql).to match(/ORDER BY .*only_search.* ASC/)
      end

      it 'lets permitted params traverse any association that exists' do
        sql = Unlisted.ransack(permitted(articles_title_eq: 'x')).result.to_sql
        expect(sql).to include 'JOIN'
        expect(sql).to match(/articles.*title.* = 'x'/)
      end

      it 'still applies the allowlist of the model it traverses to' do
        allow(Article).to receive(:ransackable_attributes).and_return(['body'])
        sql = Unlisted.ransack(permitted(articles_title_eq: 'x')).result.to_sql
        expect(sql).not_to include 'title'
      end

      it 'still checks that the attribute exists' do
        expect {
          Unlisted.ransack!(permitted(no_such_column_eq: 'x'))
        }.to raise_error(InvalidSearchError, /no_such_column_eq/)
      end

      it 'never bypasses ransackable_scopes' do
        expect(Unlisted).not_to receive(:active)
        expect(Unlisted.ransack(permitted(active: true)).result.to_sql).not_to include 'awesome'
        expect {
          Unlisted.ransack!(permitted(active: true))
        }.to raise_error(InvalidSearchError, /active/)
      end

      it 'offers everything that exists to the form helpers' do
        search = Unlisted.ransack(permitted({}))
        expect(search.context.searchable_attributes).to include 'only_sort'
        expect(search.context.sortable_attributes).to include 'only_search'
        expect(search.context.searchable_associations).to include 'articles'
      end

      it 'still asks for a list when given a plain Hash' do
        expect {
          Unlisted.ransack(only_sort_eq: 'x').result
        }.to raise_error(RuntimeError, /explicitly allowlisted/)
      end

      it 'still asks for a list when given unpermitted params' do
        expect {
          Unlisted.ransack(unpermitted(only_sort_eq: 'x')).result
        }.to raise_error(RuntimeError, /explicitly allowlisted/)
      end

      # `permit(q: {})` marks everything under q permitted; Ransack cannot tell
      # it apart from an explicit list, so for a model with no allowlist it is
      # a full bypass for that action. Documented as such.
      it 'trusts a hash permitted wholesale with permit(q: {})' do
        q = ::ActionController::Parameters.new(q: { only_sort_eq: 'x' }).permit(q: {})[:q]
        expect(q).to be_permitted
        sql = Unlisted.ransack(q).result.to_sql
        expect(sql).to match(/#{only_sort} = 'x'/)
      end
    end

    context 'a model with an allowlist' do
      it 'applies it to permitted params as well' do
        sql = Person.ransack(permitted(only_sort_eq: 'x')).result.to_sql
        expect(sql).not_to include 'only_sort'
      end

      it 'applies its sort list to permitted params as well' do
        sql = Person.ransack(permitted(s: 'only_search asc')).result.to_sql
        expect(sql).not_to include 'only_search'
      end

      it 'applies it to a hash permitted wholesale with permit(q: {})' do
        q = ::ActionController::Parameters.new(q: { only_sort_eq: 'x' }).permit(q: {})[:q]
        sql = Person.ransack(q).result.to_sql
        expect(sql).not_to include 'only_sort'
      end

      it 'applies an inherited list to a subclass' do
        sql = Musician.ransack(permitted(only_sort_eq: 'x')).result.to_sql
        expect(sql).not_to include 'only_sort'
      end

      it 'offers its own lists to the form helpers' do
        search = Person.ransack(permitted({}))
        expect(search.context.searchable_attributes).not_to include 'only_sort'
        expect(search.context.sortable_attributes).not_to include 'only_search'
      end

      it 'sorts by ransackable_attributes when that is the only list defined' do
        expect(Listed.ransack(permitted(s: 'name asc')).result.to_sql).to match(/ORDER BY .*name.* ASC/)
        expect(Listed.ransack(permitted(s: 'only_sort asc')).result.to_sql).not_to include 'only_sort'
      end
    end
  end
end
