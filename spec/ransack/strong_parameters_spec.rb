require 'spec_helper'

module Ransack
  # Strong parameters as the authorization boundary (#1403). `Person` allows
  # neither `only_sort` for searching nor `only_search` for sorting, defines
  # no `ransackable_scopes`, and `only_admin` needs `auth_object: :admin`.
  describe 'strong parameters' do
    def permitted(hash)
      ::ActionController::Parameters.new(hash).permit!
    end

    def unpermitted(hash)
      ::ActionController::Parameters.new(hash)
    end

    let(:only_sort) { "#{quote_table_name("people")}.#{quote_column_name("only_sort")}" }

    context 'by default' do
      it 'is off' do
        expect(Ransack.options[:strong_parameters]).to be false
      end

      it 'keeps the model allowlist even for permitted params' do
        sql = Person.ransack(permitted(only_sort_eq: 'x')).result.to_sql
        expect(sql).not_to include 'only_sort'
      end

      it 'trusts permitted params for one search with strong_parameters: true' do
        sql = Person.ransack(permitted(only_sort_eq: 'x'), strong_parameters: true).result.to_sql
        expect(sql).to match(/#{only_sort} = 'x'/)
      end
    end

    context 'when configured on' do
      before { Ransack.configure { |c| c.strong_parameters = true } }
      after  { Ransack.configure { |c| c.strong_parameters = false } }

      it 'lets permitted params search a column the model does not allow' do
        sql = Person.ransack(permitted(only_sort_eq: 'x')).result.to_sql
        expect(sql).to match(/#{only_sort} = 'x'/)
      end

      it 'does not consult the model allowlist at all' do
        allow(Person).to receive(:ransackable_attributes).and_raise('must not be called')
        allow(Person).to receive(:ransortable_attributes).and_raise('must not be called')
        expect {
          Person.ransack(permitted(name_eq: 'x', s: 'name asc')).result.to_sql
        }.not_to raise_error
      end

      it 'keeps the model allowlist for unpermitted params' do
        sql = Person.ransack(unpermitted(only_sort_eq: 'x')).result.to_sql
        expect(sql).not_to include 'only_sort'
      end

      it 'keeps the model allowlist for a plain Hash' do
        sql = Person.ransack(only_sort_eq: 'x').result.to_sql
        expect(sql).not_to include 'only_sort'
      end

      it 'keeps the model allowlist for one search with strong_parameters: false' do
        sql = Person.ransack(permitted(only_sort_eq: 'x'), strong_parameters: false).result.to_sql
        expect(sql).not_to include 'only_sort'
      end

      it 'still checks that the attribute exists' do
        expect {
          Person.ransack!(permitted(no_such_column_eq: 'x'))
        }.to raise_error(InvalidSearchError, /no_such_column_eq/)
      end

      it 'never bypasses ransackable_scopes' do
        expect(Person).not_to receive(:active)
        expect(Person.ransack(permitted(active: true)).result.to_sql).not_to include 'active = 1'
        expect {
          Person.ransack!(permitted(active: true))
        }.to raise_error(InvalidSearchError, /active/)
      end

      # `permit(:s)` permits the key, not the column named in its value, so a
      # trusted `s` can sort by anything that exists. Documented as such.
      it 'lets permitted params sort by a column the model does not allow' do
        sql = Person.ransack(permitted(s: 'only_search asc')).result.to_sql
        expect(sql).to match(/ORDER BY .*only_search.* ASC/)
      end

      it 'keeps ransortable_attributes for one search with strong_parameters: false' do
        sql = Person.ransack(permitted(s: 'only_search asc'), strong_parameters: false).result.to_sql
        expect(sql).not_to include 'only_search'
      end

      # The `sort_by_<name>_<dir>` convention is not gated by
      # `ransackable_scopes` in any mode: it is reached by name, takes nothing
      # from the request, and this setting neither opens nor closes it.
      it 'leaves the sort_by_ scope convention exactly as it is without strong parameters' do
        trusted = Person.ransack(permitted(s: 'reverse_name asc')).result.to_sql
        plain   = Person.ransack(s: 'reverse_name asc').result.to_sql
        expect(trusted).to eq plain
        expect(trusted).to include 'REVERSE(name) ASC'
      end

      it 'lets permitted params traverse an association the model does not allow' do
        allow(Person).to receive(:ransackable_associations).and_return([])
        sql = Person.ransack(permitted(articles_title_eq: 'x')).result.to_sql
        expect(sql).to include 'JOIN'
        expect(sql).to match(/articles.*title.* = 'x'/)
      end

      it 'offers the same lists to the form helpers' do
        search = Person.ransack(permitted({}))
        expect(search.context.searchable_attributes).to include 'only_sort'
        expect(search.context.sortable_attributes).to include 'only_search'
      end

      # `permit(q: {})` marks everything under q permitted; Ransack cannot tell
      # it apart from an explicit list, so it is a full bypass for that action.
      it 'trusts a hash permitted wholesale with permit(q: {})' do
        q = ::ActionController::Parameters.new(q: { only_sort_eq: 'x' }).permit(q: {})[:q]
        expect(q).to be_permitted
        sql = Person.ransack(q).result.to_sql
        expect(sql).to match(/#{only_sort} = 'x'/)
      end
    end
  end
end
