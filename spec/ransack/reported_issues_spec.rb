require 'spec_helper'

# Examples from closed issues that the rest of the suite did not pin down.
# Each one names the issue it comes from; most are the reporter's own
# example, adapted to the models in spec/support/schema.rb.
module Ransack
  describe 'behaviour reported in closed issues' do
    def t(name) = quote_table_name(name)
    def c(name) = quote_column_name(name)
    def col(table, name) = "#{t(table)}.#{c(name)}"
    def join_count(sql, table) = sql.scan(/JOIN #{Regexp.escape(t(table))}/).size

    # Other specs count the seeded rows, so every example's rows are rolled
    # back.
    around do |example|
      ::ActiveRecord::Base.transaction do
        example.run
        raise ::ActiveRecord::Rollback
      end
    end

    describe 'conditions and values' do
      # #458: a date given to `_lteq` on a date column was cast through the
      # time zone to the previous evening, so the day itself was left out.
      it 'includes records on the day given to lteq on a date column' do
        on_day = Person.create!(name: 'issue-458-on', life_start: Date.new(2014, 10, 28))
        Person.create!(name: 'issue-458-after', life_start: Date.new(2014, 10, 29))

        search = Person.ransack(life_start_lteq: '2014-10-28', name_start: 'issue-458')
        expect(search.result.to_sql).to include("#{col('people', 'life_start')} <= '2014-10-28'")
        expect(search.result.to_a).to eq [on_day]
      end

      # #224: an Integer value for a LIKE predicate raised
      # "undefined method `gsub' for 198:Fixnum" while its wildcards were escaped.
      it 'accepts an Integer value for cont on an integer column' do
        sql = nil
        expect { sql = Person.ransack(salary_cont: 198).result.to_sql }.not_to raise_error
        expect(sql).to include(col('people', 'salary'))
        expect(sql).to include("'%198%'")
      end

      # #224: the same through an advanced-mode condition inside a grouping.
      it 'accepts an Integer value for cont in an advanced-mode condition' do
        params = {
          g: { '0' => { m: 'or', c: { '0' => {
            a: { '0' => { name: 'salary' } }, p: 'cont', v: { '0' => { value: 198 } }
          } } } }
        }
        sql = nil
        expect { sql = Person.ransack(params).result.to_sql }.not_to raise_error
        expect(sql).to include("'%198%'")
      end

      # #812: cont on an integer column cast the value to the column type and
      # produced LIKE 0.
      it 'keeps the value as text for cont on an integer column' do
        sql = Person.ransack(salary_cont: '12').result.to_sql
        expect(sql).to match(/#{Regexp.escape(col('people', 'salary'))} I?LIKE '%12%'/)
        expect(sql).not_to match(/LIKE 0/)
      end

      # #400: an unchecked check box for a `_true` condition submits "0",
      # which raised "undefined method `name' for nil:NilClass".
      it 'treats the strings a check box submits for a _true condition as booleans' do
        field = col('people', 'awesome')
        quoted_true = ::ActiveRecord::Base.lease_connection.quoted_true

        unchecked = Person.ransack('awesome_true' => '0').result
        expect { unchecked.to_a }.not_to raise_error
        expect(unchecked.to_sql).to include("#{field} != #{quoted_true}")

        checked = Person.ransack('awesome_true' => '1').result
        expect(checked.to_sql).to include("#{field} = #{quoted_true}")
      end

      # #358: an association path given as the attribute name of an
      # advanced-mode condition inside a grouping was looked up as a column of
      # the base table instead of being joined.
      it 'joins a nested association named in an advanced-mode condition inside a grouping' do
        params = {
          g: {
            '0' => {
              m: 'and',
              c: { '0' => {
                a: { '0' => { name: 'articles_comments_body' } },
                p: 'eq', v: { '0' => { value: 'issue-358' } }
              } }
            },
            '1' => {
              m: 'or',
              c: { '0' => { a: { '0' => { name: '' } }, p: 'eq', v: { '0' => { value: '' } } } }
            }
          }
        }
        relation = Person.ransack(params).result
        sql = relation.to_sql

        expect(join_count(sql, 'articles')).to eq 1
        expect(join_count(sql, 'comments')).to eq 1
        expect(sql).to include("#{col('comments', 'body')} = 'issue-358'")
        expect { relation.to_a }.not_to raise_error
      end

      # #1354: `cont` on a serialized Array column raised
      # SerializationTypeMismatch because the LIKE pattern was cast through the
      # column's coder.
      it 'searches the stored text of a serialized attribute without casting the pattern' do
        stub_const('SerializedNote', Class.new(ApplicationRecord) {
          self.table_name = 'notes'
          serialize :note, type: Array, coder: YAML
        })
        record = SerializedNote.create!(notable_id: 0, notable_type: 'Issue1354', note: %w[L01 L02])
        SerializedNote.create!(notable_id: 0, notable_type: 'Issue1354', note: %w[L03])

        search = SerializedNote.ransack(notable_type_eq: 'Issue1354', note_cont: 'L02')
        expect { search.result.to_sql }.not_to raise_error
        expect(search.result.to_sql).to include("LIKE '%L02%'")
        expect(search.result.to_a).to eq [record]
      end

      # #840: an associated attribute was cast with the type of the searched
      # model's column of the same name (string value became 0).
      describe 'an associated column sharing its name with a column of another type' do
        before(:all) do
          ::ActiveRecord::Base.lease_connection.create_table(:houses, force: true) do |t|
            t.string :number, null: false
          end
          ::ActiveRecord::Base.lease_connection.create_table(:apartments, force: true) do |t|
            t.integer :house_id, null: false
            t.integer :number, null: false
          end
        end

        after(:all) do
          ::ActiveRecord::Base.lease_connection.drop_table(:apartments, if_exists: true)
          ::ActiveRecord::Base.lease_connection.drop_table(:houses, if_exists: true)
        end

        before do
          stub_const('House', Class.new(ApplicationRecord) { has_many :apartments })
          stub_const('Apartment', Class.new(ApplicationRecord) { belongs_to :house })
        end

        it 'casts the value with the associated column type' do
          house = House.create!(number: 'd.38g')
          apartment = Apartment.create!(house: house, number: 38)
          Apartment.create!(house: House.create!(number: '0'), number: 1)

          search = Apartment.ransack(house_number_eq: 'd.38g')
          expect(search.result.to_sql).to include("#{col('houses', 'number')} = 'd.38g'")
          expect(search.result.to_a).to eq [apartment]
        end

        it 'casts the other way round too' do
          house = House.create!(number: '12a')
          Apartment.create!(house: house, number: 12)

          search = House.ransack(apartments_number_eq: '12')
          expect(search.result.to_sql).to include("#{col('apartments', 'number')} = 12")
          expect(search.result.to_a).to eq [house]
        end
      end

      # #744 / #786: searching from a model whose primary key is not an
      # integer cast an associated integer id with the searched model's id
      # type, turning it into NULL.
      describe 'from a model with a non-integer primary key' do
        before(:all) do
          ::ActiveRecord::Base.lease_connection.create_table(:uuid_owners, id: :string, force: true) do |t|
            t.string :name
          end
          ::ActiveRecord::Base.lease_connection.create_table(:owned_items, force: true) do |t|
            t.string :uuid_owner_id
          end
          ::ActiveRecord::Base.lease_connection.create_table(:tags_uuid_owners, id: false, force: true) do |t|
            t.string :uuid_owner_id
            t.integer :tag_id
          end
        end

        after(:all) do
          %i[tags_uuid_owners owned_items uuid_owners].each do |table|
            ::ActiveRecord::Base.lease_connection.drop_table(table, if_exists: true)
          end
        end

        before do
          # Named before the associations are declared: habtm derives its join
          # model from the class name.
          stub_const('UuidOwner', Class.new(ApplicationRecord))
          UuidOwner.class_eval do
            has_many :owned_items
            has_and_belongs_to_many :tags, join_table: 'tags_uuid_owners'
          end
          stub_const('OwnedItem', Class.new(ApplicationRecord) { belongs_to :uuid_owner })
        end

        # #744
        it 'casts an associated has_many id as an integer' do
          owner = UuidOwner.create!(id: 'f47ac10b-58cc-4372-a567-0e02b2c3d479')
          item = OwnedItem.create!(uuid_owner: owner)

          search = UuidOwner.ransack(owned_items_id_eq: item.id.to_s)
          expect(search.result.to_sql).to include("#{col('owned_items', 'id')} = #{item.id}")
          expect(search.result.to_a).to eq [owner]
        end

        # #786
        it 'casts an associated has_and_belongs_to_many id as an integer' do
          owner = UuidOwner.create!(id: '9c858901-8a57-4791-81fe-4c455b099bc9')
          tag = Tag.create!(name: 'issue-786')
          owner.tags << tag

          search = UuidOwner.ransack(tags_id_eq: tag.id.to_s)
          expect(search.result.to_sql).to include("#{col('tags', 'id')} = #{tag.id}")
          expect(search.result.to_a).to eq [owner]
        end
      end
    end

    describe 'predicates' do
      # #1404: not_cont_any is "does not contain at least one of" (NOT LIKE
      # joined by OR); not_cont_all is the "contains none of" search.
      describe 'not_cont_any and not_cont_all' do
        before do
          Person.create!(name: 'q1404-cat')
          Person.create!(name: 'q1404-dim')
        end

        def names(params)
          Person.ransack({ name_start: 'q1404-' }.merge(params)).result.map(&:name)
        end

        it 'keeps a value missing any one of the terms with not_cont_any' do
          expect(names(name_not_cont_any: %w[a t])).to contain_exactly('q1404-dim')
          expect(names(name_not_cont_any: %w[a i])).to contain_exactly('q1404-cat', 'q1404-dim')
        end

        it 'keeps only values containing none of the terms with not_cont_all' do
          expect(names(name_not_cont_all: %w[a i])).to be_empty
          expect(names(name_not_cont_all: %w[a t])).to contain_exactly('q1404-dim')
        end
      end

      describe 'custom predicates' do
        around do |example|
          saved = Ransack.predicates
          copy = Configuration::PredicateCollection.new
          saved.keys.each { |key| copy[key] = saved[key] }
          Ransack.predicates = copy
          example.run
        ensure
          Ransack.predicates = saved
        end

        # #1649: a custom predicate declared with `type: :date` handed its
        # formatter the raw String instead of a Date (4.4.0 regression).
        it 'casts the value to the declared type before the formatter runs' do
          Ransack.configure do |config|
            config.add_predicate 'issue1649_lteq_eod',
              arel_predicate: 'lteq',
              formatter: proc { |value| value.end_of_day },
              type: :date,
              compounds: false
          end
          received = nil
          allow(Ransack.predicates['issue1649_lteq_eod']).to receive(:format).and_wrap_original do |m, v|
            received = v
            m.call(v)
          end

          sql = Person.ransack(created_at_issue1649_lteq_eod: '2024-03-05').result.to_sql
          expect(received).to eq Date.new(2024, 3, 5)
          expect(sql).to include("#{col('people', 'created_at')} <=")
        end

        # #32: `arel_predicate: 'in'` forced wants_array, so the Range a
        # formatter returned was wrapped in an Array and Arel could not visit it.
        it 'filters by a Range a formatter returns when wants_array is false' do
          Ransack.configure do |config|
            config.add_predicate 'issue32_within_a_day',
              arel_predicate: 'in', wants_array: false,
              formatter: proc { |date| date..(date + 1) }
          end
          inside = Person.create!(name: 'issue32 inside', life_start: Date.new(2012, 1, 2))
          Person.create!(name: 'issue32 outside', life_start: Date.new(2012, 1, 5))

          result = Person.ransack(name_start: 'issue32', life_start_issue32_within_a_day: '2012-01-01').result
          expect(result.to_a).to eq [inside]
        end
      end
    end

    describe 'scopes' do
      before do
        allow(Person).to receive(:ransackable_scopes).and_return(%i[active over_age])
      end

      # #1490: a scope given 1 inside an index-keyed `g` hash was not applied.
      it 'applies a no-argument scope given 1 inside an index-keyed grouping' do
        sql = Person.ransack(g: { '0' => { active: 1 } }).result.to_sql
        expect(sql).to include('active = 1')
      end

      # #1490
      it 'applies a scope with an argument inside an index-keyed grouping' do
        sql = Person.ransack(g: { '0' => { over_age: 18 } }).result.to_sql
        expect(sql).to match(/age > '?18'?/)
      end

      # #401: scopes listed by name as strings (`%w[fulltext]`) were ignored.
      it 'applies scopes listed as strings' do
        allow(Person).to receive(:ransackable_scopes).and_return(%w[active over_age])
        sql = Person.ransack('active' => true, 'over_age' => 18).result.to_sql
        expect(sql).to include('active = 1')
        expect(sql).to match(/age > '?18'?/)
      end

      # #369: Ransack defined `search` on every model, so Rails refused a scope
      # of that name as dangerous.
      it 'lets a model define a scope named search' do
        expect(Person).not_to respond_to(:search)
        model = Class.new(ApplicationRecord) { self.table_name = 'people' }
        expect { model.scope :search, ->(term) { where(name: term) } }.not_to raise_error
      end
    end

    describe 'ransackers' do
      # #914: a string ransacker searched alongside an integer condition had
      # its value cast to an integer (LIKE 123).
      it 'keeps the type of a string ransacker next to an integer condition' do
        [
          { salary_eq: 1, name_case_insensitive_matches: '123,124' },
          { name_case_insensitive_matches: '123,124', salary_eq: 1 }
        ].each do |params|
          sql = Person.ransack(params).result.to_sql
          expect(sql).to match(/LOWER\(#{Regexp.escape(col('people', 'name'))}\) I?LIKE '123,124'/)
          expect(sql).to include("#{col('people', 'salary')} = 1")
        end
      end

      # #442: an untyped SQL-literal ransacker at the start of an `_or_`
      # condition had the value cast as an integer: `LIKE 0` instead of
      # `LIKE '%123%'`.
      it 'keeps the string value for an untyped SQL literal first in an _or_ cont' do
        stub_const('PersonWithIdAsText', Class.new(Person) {
          ransacker(:id_as_text) { Arel.sql('CAST(people.id AS CHAR)') }
        })
        sql = PersonWithIdAsText.ransack(id_as_text_or_articles_title_cont: '123').result.to_sql
        expect(sql).to include('CAST(people.id AS CHAR)')
        expect(sql.scan("'%123%'").size).to eq 2
        expect(sql).not_to match(/LIKE 0\b/)
      end

      # #221: Grouping ransackers combined with `_true` in `or` groupings
      # raised NoMethodError (`name` for Arel::Nodes::Grouping) when one
      # grouping was true and the other false.
      it 'combines Grouping ransackers with mixed true / false _true values' do
        stub_const('PersonWithPayRansackers', Class.new(Person) {
          ransacker :well_paid do |parent|
            Arel::Nodes::Grouping.new(
              Arel::Nodes::InfixOperation.new('AND',
                Arel::Nodes::InfixOperation.new('>', parent.table[:salary], 0),
                Arel::Nodes::InfixOperation.new('>=', parent.table[:salary], 100)))
          end

          ransacker :unpaid do |parent|
            Arel::Nodes::Grouping.new(Arel::Nodes::InfixOperation.new('<=', parent.table[:salary], 0))
          end
        })
        params = { m: 'or', g: { '0' => { 'well_paid_true' => true }, '1' => { 'unpaid_true' => false } } }
        relation = PersonWithPayRansackers.ransack(params).result
        sql = relation.to_sql

        salary = col('people', 'salary')
        expect(sql).to include("(#{salary} > 0 AND #{salary} >= 100)")
        expect(sql).to include("(#{salary} <= 0) !=")
        expect(sql).to match(/ OR /)
        expect { relation.to_a }.not_to raise_error
      end

      # #617: a ransacker built from Arel.sql produced `x != NULL` (always
      # unknown) instead of `x IS NOT NULL` for the present predicate.
      it 'builds IS NOT NULL for present on an Arel.sql ransacker' do
        stub_const('PersonWithSqlNameRansacker', Class.new(Person) {
          ransacker(:sql_name, type: :string) { Arel.sql('people.name') }
        })
        sql = PersonWithSqlNameRansacker.ransack(sql_name_present: true).result.to_sql
        expect(sql).to include("people.name IS NOT NULL AND people.name != ''")
        expect(sql).not_to include('!= NULL')
      end

      # #601: a ransacker whose formatter returns an array worked with _in
      # but produced NOT IN (NULL) with _not_in.
      it 'applies an array-returning formatter to not_in as well as in' do
        ids = Person.first(2).map(&:id)
        in_ids = Person.ransack(array_people_ids_in: 'x').result.pluck(:id)
        not_in_ids = Person.ransack(array_people_ids_not_in: 'x').result.pluck(:id)

        expect(in_ids).to match_array ids
        expect(not_in_ids).not_to be_empty
        expect(not_in_ids & ids).to be_empty
        expect(Person.ransack(array_people_ids_not_in: 'x').result.to_sql).not_to include('NULL')
      end

      # #543: with a joins on the relation, a string value given to a
      # string-typed SqlLiteral ransacker was cast to 0.
      it 'keeps a string value for a SqlLiteral ransacker when the relation has joins' do
        stub_const('PersonWithStatusRansacker', Class.new(Person) {
          ransacker :status, type: :string do
            Arel.sql("CASE WHEN people.name = 'A' THEN 'STATUS_FOO' ELSE 'STATUS_BAR' END")
          end
        })
        sql = PersonWithStatusRansacker.joins(:articles).ransack(status_eq: 'STATUS_FOO').result.to_sql
        expect(sql).to include("END = 'STATUS_FOO'")

        sql = PersonWithStatusRansacker.joins(:articles).ransack(status_cont: 'FOO').result.to_sql
        expect(sql).to include("LIKE '%FOO%'")
      end

      # #99: with a join on the relation the date value of a NamedFunction
      # ransacker was cast as an integer (`= 2012`).
      it 'keeps the value of a NamedFunction ransacker when the relation has joins' do
        stub_const('PersonWithCreatedOn', Class.new(ApplicationRecord) {
          self.table_name = 'people'
          has_many :articles, foreign_key: :person_id

          ransacker :created_on do |parent|
            Arel::Nodes::NamedFunction.new('DATE', [parent.table[:created_at]])
          end
        })
        relation = PersonWithCreatedOn.joins(:articles).ransack(created_on_eq: '2012-05-21').result
        expect(relation.to_sql).to include("= '2012-05-21'")
        expect { relation.count }.not_to raise_error
      end

      # #702: an SqlLiteral subquery returned by a ransacker formatter was cast
      # to the attribute type, giving IN (0).
      it 'passes an SqlLiteral subquery from a formatter through to IN' do
        stub_const('PersonWithNameSubquery', Class.new(Person) {
          ransacker :id_by_name,
                    callable: ->(parent) { parent.table[:id] },
                    formatter: ->(value) {
                      Arel.sql(Person.unscoped.select(:id).where(name: value).to_sql)
                    }
        })
        person = Person.create!(name: 'issue-702')

        relation = PersonWithNameSubquery.ransack(id_by_name_in: 'issue-702').result
        expect(relation.to_sql).to include("#{col('people', 'id')} IN (SELECT")
        expect(relation.map(&:id)).to eq [person.id]
      end
    end

    describe 'ransack_alias' do
      # #1239: when the alias came before the attribute it points at, both
      # conditions mapped to the same key and the alias's was overwritten.
      it 'keeps both conditions when an alias and its target share a predicate, in either order' do
        parent_name = col('parents_people', 'name')

        [
          { daddy_not_eq: 'Alias', parent_name_not_eq: 'Target' },
          { parent_name_not_eq: 'Target', daddy_not_eq: 'Alias' }
        ].each do |params|
          sql = Person.ransack(params).result.to_sql
          expect(sql).to include("#{parent_name} != 'Alias'")
          expect(sql).to include("#{parent_name} != 'Target'")
        end
      end

      # #806: aliases were kept on ActiveRecord::Base, so the same alias name
      # on two models clobbered one another and the search was dropped.
      it 'keeps same-named aliases on different models apart' do
        stub_const('PersonWithQuickAlias', Class.new(Person) { ransack_alias :quick, :email })
        stub_const('ArticleWithQuickAlias', Class.new(ApplicationRecord) {
          self.table_name = 'articles'
          self.inheritance_column = nil
          ransack_alias :quick, :title
        })

        expect(PersonWithQuickAlias.ransack(quick_cont: 'a').result.to_sql)
          .to match(/#{Regexp.escape(col('people', 'email'))} I?LIKE '%a%'/)
        expect(ArticleWithQuickAlias.ransack(quick_cont: 'b').result.to_sql)
          .to match(/#{Regexp.escape(col('articles', 'title'))} I?LIKE '%b%'/)
        expect(Person.ransack(quick_cont: 'c').result.to_sql).not_to include("'%c%'")
      end

      # #720: m: 'or' next to an aliased key was dropped and the conditions
      # were ANDed.
      it "combines an aliased condition with another one under m: 'or'" do
        sql = Person.ransack(term_cont: 'x', salary_eq: 1, m: 'or').result.to_sql
        expect(sql).to include(") OR #{col('people', 'salary')} = 1")
      end
    end

    describe 'associations' do
      # #1558: a condition two belongs_to levels deep returned nothing.
      it 'filters through two belongs_to levels' do
        person = Person.create!(name: 'issue-1558', email: 'issue-1558@example.com')
        comment = Comment.create!(article: Article.create!(person: person), person: person)

        search = Comment.ransack(article_person_email_cont: 'issue-1558@')
        sql = search.result.to_sql
        expect(sql).to include("JOIN #{t('articles')}")
        expect(sql).to include("JOIN #{t('people')}")
        expect(search.result.to_a).to eq [comment]
      end

      # #1428: an `_or_` of several attributes on a belongs_to raised
      # "undefined method" on the search.
      it 'ORs several attributes of a belongs_to' do
        article = Article.create!(title: 'issue-1428-title', body: 'issue-1428-body')
        comment = Comment.create!(article: article)

        key = :article_title_or_article_body_cont
        search = Comment.ransack(key => 'issue-1428-body')
        expect(search.public_send(key)).to eq 'issue-1428-body'
        sql = search.result.to_sql
        expect(sql).to include("#{col('articles', 'title')} LIKE")
        expect(sql).to include(' OR ')
        expect(sql).to include("#{col('articles', 'body')} LIKE")
        expect(search.result.to_a).to eq [comment]
      end

      # #1415: searching through a has_one :through and sorting on the
      # intermediate belongs_to ordered by an alias that was never joined.
      it 'sorts on the intermediate association of a has_one :through condition' do
        boston = Address.create!(city: 'issue-1415-Boston')
        emp_b = Employee.create!(name: 'issue-1415-b', organization: Organization.create!(name: 'issue-1415-b', address: boston))
        emp_a = Employee.create!(name: 'issue-1415-a', organization: Organization.create!(name: 'issue-1415-a', address: boston))

        search = Employee.ransack(address_city_cont: 'issue-1415-Bos', s: 'organization_name asc')
        sql = search.result.to_sql
        expect(join_count(sql, 'organizations')).to eq 1
        expect(sql).to include("ORDER BY #{col('organizations', 'name')} ASC")
        expect(search.result.to_a).to eq [emp_a, emp_b]
      end

      # #1423 / #1531: a condition on a has_many :through together with one on
      # its intermediate has_many referenced the table name where the join was
      # aliased (or the alias where nothing was joined).
      it 'searches a has_many :through and its intermediate association, in either param order' do
        person = Person.create!(name: 'issue-1423')
        article = Article.create!(person: person, title: 'issue-1423-title')
        Comment.create!(article: article, person: person, body: 'issue-1423-body')
        Article.create!(person: Person.create!(name: 'issue-1423-other'), title: 'issue-1423-title')

        params = { authored_article_comments_body_eq: 'issue-1423-body', articles_title_eq: 'issue-1423-title' }
        [params, params.to_a.reverse.to_h].each do |ordered|
          expect(Person.ransack(ordered).result(distinct: true).to_a).to eq [person]
        end
      end

      # #1182: two belongs_to associations to one table; the second param's
      # condition referenced an alias the joins did not define.
      it 'binds each belongs_to to one table to its own join, in either param order' do
        person = Person.create!(name: 'issue-1182-left')
        target = Person.create!(name: 'issue-1182-right')
        recommendation = Recommendation.create!(person: person, target_person: target)

        params = { person_name_eq: 'issue-1182-left', target_person_name_eq: 'issue-1182-right' }
        [params, params.to_a.reverse.to_h].each do |ordered|
          expect(Recommendation.ransack(ordered).result.to_a).to eq [recommendation]
        end

        swapped = { person_name_eq: 'issue-1182-right', target_person_name_eq: 'issue-1182-left' }
        [swapped, swapped.to_a.reverse.to_h].each do |ordered|
          expect(Recommendation.ransack(ordered).result.to_a).to be_empty
        end
      end

      # #1151: two scoped associations to one table in one _or_ condition;
      # each attribute was bound to the other association's alias.
      it 'binds each attribute of an _or_ condition over two scoped associations to its own join' do
        person = Person.create!(name: 'issue-1151')
        Article.create!(person: person, title: 'issue-1151-draft', published: false)

        sql = Person.ransack(articles_title_or_published_articles_title_cont: 'x').result.to_sql
        expect(sql).to include("#{col('articles', 'title')} LIKE")
        expect(sql).to include("#{col('published_articles_people', 'title')} LIKE")
        expect(sql).to match(/JOIN #{Regexp.escape(t('articles'))} (AS )?#{Regexp.escape(t('published_articles_people'))} ON/)

        expect(Person.ransack(articles_title_or_published_articles_title_cont: 'issue-1151-draft').result.to_a)
          .to eq [person]
        expect(Person.ransack(published_articles_title_cont: 'issue-1151-draft').result.to_a).to be_empty
      end

      # #986: several through associations sharing one intermediate
      # association joined the intermediate table once each.
      it 'joins an intermediate association shared by two through associations once' do
        stub_const('EmployeeWithColleagues', Class.new(ApplicationRecord) {
          self.table_name = 'employees'
          belongs_to :organization
          has_one :address, through: :organization
          has_many :colleagues, through: :organization, source: :employees
        })

        relation = EmployeeWithColleagues.ransack(address_city_eq: 'Boston', colleagues_name_eq: 'Bert').result
        expect(join_count(relation.to_sql, 'organizations')).to eq 1
        expect { relation.to_a }.not_to raise_error
      end

      # #1217: with the through association first in the _or_ name, the
      # intermediate association's attribute referenced a missing alias.
      it 'matches a has_one :through in an _or_ condition, whichever association comes first' do
        address = Address.create!(city: 'issue-1217-city')
        organization = Organization.create!(name: 'issue-1217-org', address: address)
        employee = Employee.create!(name: 'issue-1217', organization: organization)

        %w[address_city_or_organization_name_cont organization_name_or_address_city_cont].each do |key|
          expect(Employee.ransack(key => 'issue-1217-city').result.to_a).to eq [employee]
          expect(Employee.ransack(key => 'issue-1217-org').result.to_a).to eq [employee]
          expect(Employee.ransack(key => 'issue-1217-nothing').result.to_a).to be_empty
        end
      end

      # #748: the target's default scope was put back on the join of an
      # association that unscopes it.
      it 'honours an association that unscopes the default scope of its target' do
        stub_const('ArticleWithAllComments', Class.new(ApplicationRecord) {
          self.table_name = 'articles'
          self.inheritance_column = nil
          has_many :all_comments, -> { unscope(where: :disabled) },
                   class_name: 'Comment', foreign_key: :article_id
        })
        article = Article.create!(title: 'issue-748')
        Comment.create!(article: article, body: 'issue-748 disabled comment', disabled: true)

        search = ArticleWithAllComments.ransack(all_comments_body_cont: 'issue-748 disabled')
        expect(search.result.to_sql).not_to include(c('disabled'))
        expect(search.result.map(&:id)).to eq [article.id]
      end

      # #35: `record.through_association.ransack` raised NoMethodError
      # (`table_aliases` on the JoinDependency).
      it 'searches within a has_many :through association of a record' do
        person = Person.create!(name: 'issue35')
        article = Article.create!(person: person, title: 'issue35')
        comment = Comment.create!(article: article, body: 'issue35 through')
        Comment.create!(article: article, body: 'issue35 other')

        expect(person.authored_article_comments.ransack(body_cont: 'through').result.to_a).to eq [comment]
      end

      # #1142: a has_many reached through a scoped, self-referential
      # has_many :through was joined before the aliased table it hangs off,
      # giving "missing FROM-clause entry" for that alias.
      describe 'an association of a self-referential has_many :through' do
        before(:all) do
          ::ActiveRecord::Base.lease_connection.create_table(:issue_relationships, force: true) do |t|
            t.integer :parent_id
            t.integer :child_id
            t.string  :relationship_type
          end
        end

        after(:all) do
          ::ActiveRecord::Base.lease_connection.drop_table(:issue_relationships, if_exists: true)
        end

        before do
          stub_const('IssueRelationship', Class.new(ApplicationRecord) {
            self.table_name = 'issue_relationships'
            belongs_to :child, class_name: 'IssueContact'
          })
          stub_const('IssueContact', Class.new(ApplicationRecord) {
            self.table_name = 'people'
            has_many :council_relationships, -> { where(relationship_type: 'student_council') },
                     class_name: 'IssueRelationship', foreign_key: :parent_id
            has_many :student_councils, through: :council_relationships, source: :child
            has_many :articles, foreign_key: :person_id
          })
        end

        it 'joins the aliased through table before the association hanging off it' do
          sql = IssueContact.ransack(student_councils_articles_id_null: true).result.to_sql
          alias_join = sql.index(/JOIN #{Regexp.escape(t('people'))} (AS )?#{Regexp.escape(t('student_councils_people'))} ON/)
          articles_join = sql.index("JOIN #{t('articles')}")
          expect(alias_join).not_to be_nil
          expect(articles_join).to be > alias_join
          expect(sql).to include("#{col('articles', 'person_id')} = #{col('student_councils_people', 'id')}")
        end

        it 'returns the records whose related records have none' do
          with_articles = IssueContact.create!(name: 'issue-1142-with')
          without_articles = IssueContact.create!(name: 'issue-1142-without')
          busy_council = IssueContact.create!(name: 'issue-1142-busy-council')
          idle_council = IssueContact.create!(name: 'issue-1142-idle-council')
          IssueRelationship.create!(parent_id: with_articles.id, child: busy_council, relationship_type: 'student_council')
          IssueRelationship.create!(parent_id: without_articles.id, child: idle_council, relationship_type: 'student_council')
          Article.create!(person_id: busy_council.id, title: 'issue-1142')

          result = IssueContact.ransack(student_councils_articles_id_null: true, name_start: 'issue-1142').result.to_a
          expect(result).to include(without_articles)
          expect(result).not_to include(with_articles)
        end
      end
    end

    describe 'polymorphic associations' do
      # #159: searching a polymorphic association's own `_type` column raised
      # `uninitialized constant Note::Notable`.
      it 'searches the _type and _id columns of a polymorphic belongs_to without a join' do
        sql = Note.ransack(notable_type_eq: 'Person', notable_id_eq: 1).result.to_sql
        expect(sql).to include("#{col('notes', 'notable_type')} = 'Person'")
        expect(sql).to include("#{col('notes', 'notable_id')} = 1")
        expect(sql).not_to include('JOIN')

        types = Note.ransack(notable_type_cont: 'Pers').result.map(&:notable_type)
        expect(types).not_to be_empty
        expect(types.uniq).to eq ['Person']
      end

      # #93: a polymorphic association named without `_of_<Type>_type`
      # raised ActiveRecord::EagerLoadPolymorphicError.
      it 'ignores a condition that names no type' do
        search = Note.ransack(notable_name_cont: 'x')
        expect(search.base.conditions).to be_empty
        expect { search.result.to_a }.not_to raise_error
      end

      # #93: a strict search says why the condition could not be used.
      it 'raises for a condition that names no type in a strict search' do
        expect { Note.ransack!(notable_name_cont: 'x') }
          .to raise_error(InvalidSearchError, /notable_name_cont/)
      end

      # #161: scoping the relation to one type does not make the typeless
      # condition usable; the scope stays and nothing is joined.
      it 'keeps a type scope on the relation and adds no join' do
        sql = Note.where(notable_type: 'Person').ransack(notable_name_cont: 'x').result.to_sql
        expect(sql).to include("#{col('notes', 'notable_type')} = 'Person'")
        expect(sql).not_to include('JOIN')
      end

      # #30: a value with a `.` in it, searched through `_of_<Type>_type`,
      # raised EagerLoadPolymorphicError once the result included the
      # association.
      it 'searches through a type with a dotted value and includes the association' do
        person = Person.create!(name: 'issue30', email: 'issue30@dotted.example.org')
        note = Note.create!(notable: person, note: 'issue30')

        result = Note.ransack(notable_of_Person_type_email_cont: 'issue30@dotted.example').result.includes(:notable)
        expect(result.to_a).to eq [note]
        expect(result.first.notable).to eq person
      end

      # #661: two polymorphic types joined with _or_ in one condition name.
      it 'searches both polymorphic types with one predicate' do
        key = :notable_of_Person_type_name_or_notable_of_Article_type_title_start
        sql = Note.ransack(key => 'Ab').result.to_sql
        expect(sql).to match(/#{Regexp.escape(col('people', 'name'))} LIKE 'Ab%'/)
        expect(sql).to match(/#{Regexp.escape(col('articles', 'title'))} LIKE 'Ab%'/)
        expect { Note.ransack!(key => 'Ab').result.to_a }.not_to raise_error
      end

      # #865: a polymorphic belongs_to can be followed into the target's own
      # associations once its type is named.
      it "walks past a typed polymorphic belongs_to into the target's associations" do
        author = Person.create!(name: 'issue-865-author')
        note = Note.create!(notable: Article.create!(person: author, title: 'issue-865'), note: 'issue-865 note')
        Note.create!(notable: author, note: 'issue-865 note on the person')

        search = Note.ransack(notable_of_Article_type_person_name_eq: 'issue-865-author')
        expect(search.result.to_sql).to include("#{col('notes', 'notable_type')} = 'Article'")
        expect(search.result.to_a).to eq [note]
      end

      # #1016: a polymorphic association reached through two belongs_to
      # associations to the same table; the second polymorphic join
      # correlated with the first parent's table, not its own alias.
      it 'correlates a polymorphic join with the alias of the parent it is reached through' do
        person = Person.create!(name: 'issue-1016-person')
        target = Person.create!(name: 'issue-1016-target')
        Note.create!(notable: person, note: 'issue-1016-person-note')
        Note.create!(notable: target, note: 'issue-1016-target-note')
        recommendation = Recommendation.create!(person: person, target_person: target)

        search = Recommendation.ransack(
          person_notes_note_or_person_email_cont: 'issue-1016-person-note',
          target_person_notes_note_or_target_person_email_cont: 'issue-1016-target-note'
        )
        expect(search.result.to_sql).to include(
          "#{col('notes_people', 'notable_id')} = #{col('target_people_recommendations', 'id')}"
        )
        expect(search.result.to_a).to eq [recommendation]
      end

      # #996: an association of a polymorphic target was INNER JOINed, which
      # filtered out every record of the other polymorphic type in an _or_
      # search, and the polymorphic joins were not limited by type.
      describe 'reached through an _or_ over two types' do
        let(:key) { :notable_of_Person_type_name_or_notable_of_Article_type_comments_body_cont }

        it 'left outer joins it and keeps each polymorphic join limited by type' do
          sql = Note.ransack(key => 'x').result.to_sql
          expect(sql).not_to include('INNER JOIN')
          expect(sql).to include("LEFT OUTER JOIN #{t('comments')}")
          expect(sql).to include("#{col('notes', 'notable_type')} = 'Person'")
          expect(sql).to include("#{col('notes', 'notable_type')} = 'Article'")
        end

        it 'returns records of either type' do
          person = Person.create!(name: 'issue-996-match')
          article = Article.create!(title: 'issue-996')
          Comment.create!(article: article, body: 'issue-996-match')
          person_note = Note.create!(notable: person, note: 'issue-996')
          article_note = Note.create!(notable: article, note: 'issue-996')

          result = Note.ransack(key => 'issue-996-match').result.distinct.to_a
          expect(result).to match_array [person_note, article_note]
        end
      end

      # Taggings in the acts-as-taggable-on shape: a polymorphic join model
      # with a context column.
      describe 'associations through a polymorphic join model' do
        before(:all) do
          ::ActiveRecord::Base.lease_connection.create_table(:issue_taggings, force: true) do |t|
            t.integer :tag_id
            t.integer :taggable_id
            t.string  :taggable_type
            t.string  :context
          end
        end

        after(:all) do
          ::ActiveRecord::Base.lease_connection.drop_table(:issue_taggings, if_exists: true)
        end

        before do
          stub_const('IssueTagging', Class.new(ApplicationRecord) {
            self.table_name = 'issue_taggings'
            belongs_to :tag
            belongs_to :taggable, polymorphic: true
          })
          stub_const('TaggedPerson', Class.new(ApplicationRecord) {
            self.table_name = 'people'
            has_many :issue_taggings, -> { where(context: 'tags') }, as: :taggable, class_name: 'IssueTagging'
            has_many :tags, through: :issue_taggings
          })
          stub_const('TaggingTag', Class.new(ApplicationRecord) {
            self.table_name = 'tags'
            has_many :issue_taggings, foreign_key: :tag_id
            has_many :tagged_people, through: :issue_taggings, source: :taggable, source_type: 'TaggedPerson'
          })

          test_tag = Tag.create!(name: 'issue-1240-test')
          IssueTagging.create!(tag: test_tag, taggable: tagged, context: 'tags')
          IssueTagging.create!(tag: test_tag, taggable: skills, context: 'skills')
        end

        let!(:tagged)   { TaggedPerson.create!(name: 'issue-1240-tagged') }
        let!(:skills)   { TaggedPerson.create!(name: 'issue-1240-other-context') }
        let!(:untagged) { TaggedPerson.create!(name: 'issue-1240-untagged') }

        def names(params)
          TaggedPerson.ransack(params.merge(name_start: 'issue-1240')).result.pluck(:name)
        end

        # #1240: a negative condition on the scoped has_many :through raised
        # NoMethodError (`eq` for nil) while building the correlated subquery.
        it 'builds a subquery for a negative condition on the scoped has_many :through' do
          expect(TaggedPerson.ransack(tags_name_not_eq: 'issue-1240-test').result.to_sql).to include('NOT IN (SELECT')
          expect(TaggedPerson.ransack(tags_name_not_in: ['issue-1240-test']).result.to_sql).to include('NOT IN (SELECT')
        end

        # #1240
        it 'excludes only records tagged through the scoped association' do
          expected = %w[issue-1240-other-context issue-1240-untagged]
          expect(names(tags_name_not_eq: 'issue-1240-test')).to match_array expected
          expect(names(tags_name_not_in: ['issue-1240-test'])).to match_array expected
          expect(names(tags_name_eq: 'issue-1240-test')).to eq ['issue-1240-tagged']
        end

        # #1039: searching a has_many :through whose source is a polymorphic
        # belongs_to raised NoMethodError (`polymorphic?` for
        # PolymorphicReflection), and the join ignored the source type.
        it 'searches through a polymorphic belongs_to source, limited to its source_type' do
          other_tag = TaggingTag.create!(name: 'issue-1039-other-type')
          IssueTagging.create!(tag_id: other_tag.id, taggable_type: 'Article', taggable_id: untagged.id, context: 'tags')

          sql = TaggingTag.ransack(tagged_people_name_eq: 'x').result.to_sql
          expect(sql).to include("#{col('issue_taggings', 'taggable_type')} = 'TaggedPerson'")

          result = TaggingTag.ransack(tagged_people_name_start: 'issue-1240').result.distinct.pluck(:name)
          expect(result).to match_array ['issue-1240-test']
        end
      end
    end

    describe 'negative conditions on a collection' do
      # #98: `_not_in` still returned a record when it had any other
      # associated row that did not match.
      it 'excludes a record that has one matching row among others' do
        excluded = Person.create!(name: 'issue98 excluded')
        Article.create!(person: excluded, title: 'issue98 match')
        Article.create!(person: excluded, title: 'issue98 other')
        kept = Person.create!(name: 'issue98 kept')
        Article.create!(person: kept, title: 'issue98 other')

        result = Person.ransack(name_start: 'issue98', articles_title_not_in: ['issue98 match']).result
        expect(result.to_a).to eq [kept]
      end

      # #1257: a negative condition on a has_many, on a relation that
      # already joins a different (belongs_to) association, raised
      # NoMethodError (`children` for nil).
      it 'searches not_null on a has_many of a relation joining a belongs_to' do
        author = Person.create!(name: 'issue-1257-author')
        with_comment = Article.create!(person: author, title: 'issue-1257-with')
        without_comment = Article.create!(person: author, title: 'issue-1257-without')
        Comment.create!(article: with_comment, body: 'issue-1257')

        relation = Article.joins(:person).where(person_id: author.id)
        expect(relation.ransack(comments_id_not_null: true).result.to_a).to eq [with_comment]
        expect(relation.ransack(comments_id_not_null: false).result.to_a).to eq [without_comment]
      end

      # #770: a negative condition on a collection raised NoMethodError
      # (join_root for a Symbol) when the relation joined another association.
      it 'works on a relation that joins a different association' do
        person = Person.create!(name: 'issue-770')
        tag = Tag.create!(name: 'issue-770-tag')
        tagged = Article.create!(person: person, title: 'issue-770 tagged')
        tagged.tags << tag
        untagged = Article.create!(person: person, title: 'issue-770 untagged')

        relation = Article.joins(:person).where(person_id: person.id).ransack(tags_id_not_in: [tag.id]).result
        expect(relation.to_a).to eq [untagged]
      end

      # #827: not_in through a has_many :through raised ArgumentError.
      it 'builds and runs not_in on a has_many :through' do
        relation = Person.ransack(authored_article_comments_id_not_in: [Comment.first.id]).result
        expect { relation.to_a }.not_to raise_error
      end
    end

    describe 'searching a relation that already has joins' do
      # #1253: with Ransack loaded, the second join to the same table was
      # dropped from a plain Active Record relation.
      it 'leaves joins and left_outer_joins to the same table alone' do
        sql = Recommendation.joins(:person).left_outer_joins(:target_person).to_sql
        expect(sql).to include("INNER JOIN #{t('people')} ON")
        expect(sql).to match(
          /LEFT OUTER JOIN #{Regexp.escape(t('people'))} (AS )?#{Regexp.escape(t('target_people_recommendations'))} ON/
        )
      end

      # #542: a relation that joins an association (the report's came from a
      # default scope or a policy scope), searched on that association and on
      # one reached through it, referred to an aliased copy of the joined
      # table that was never joined.
      it 'binds conditions on a joined association and one through it to the existing join, in either order' do
        conditions = { article_person_name_cont: 'a', article_title_cont: 'b' }
        [conditions, conditions.to_a.reverse.to_h].each do |params|
          relation = Comment.joins(:article).ransack(params).result
          sql = relation.to_sql
          expect(sql).to include("#{col('articles', 'title')} LIKE '%b%'")
          expect(sql).to include("#{col('people', 'name')} LIKE '%a%'")
          expect(join_count(sql, 'articles')).to eq 1
          expect { relation.to_a }.not_to raise_error
        end
      end

      # #419: with the nested join already on the relation, putting the
      # deeper condition first bound the other one to an alias that was never
      # joined ("no such column: order_lines_product_lines.line_type").
      it 'binds both conditions on a joined chain whatever their order' do
        person = Person.create!(name: 'issue-419-person')
        article = Article.create!(person: person, title: 'issue-419-title')
        comment = Comment.create!(article: article, person: person, body: 'issue-419')

        params = { article_title_eq: 'issue-419-title', article_person_name_eq: 'issue-419-person' }
        [params, params.to_a.reverse.to_h].each do |ordered|
          result = Comment.joins(article: :person).ransack(ordered).result
          expect(result.to_sql).not_to include('LEFT OUTER JOIN')
          expect(result.to_a).to eq [comment]
        end
      end

      # #628: with a default scope joining one association, a search on a
      # second association and on the default-scoped one used an alias
      # (documents_revisions) instead of the joined table.
      it 'uses the default scope join for a condition alongside another association' do
        stub_const('CommentJoiningArticle', Class.new(Comment) { default_scope { joins(:article) } })
        params = { person_name_eq: 'x', article_title_eq: 'y' }
        [params, params.to_a.reverse.to_h].each do |ordered|
          relation = CommentJoiningArticle.ransack(ordered).result
          expect(relation.to_sql).to include("#{col('articles', 'title')} = 'y'")
          expect(join_count(relation.to_sql, 'articles')).to eq 1
          expect { relation.to_a }.not_to raise_error
        end
      end

      # #621: searching an eager_load relation added a second, aliased
      # LEFT OUTER JOIN to the same table.
      it 'reuses the join of an eager_load' do
        relation = Person.eager_load(:articles).ransack(articles_title_cont: 'x').result
        expect(join_count(relation.to_sql, 'articles')).to eq 1
        expect(relation.to_sql).to include("#{col('articles', 'title')} LIKE '%x%'")
        expect { relation.to_a }.not_to raise_error
      end

      # #457: a relation carrying a string join (as acts-as-taggable-on adds)
      # raised NameError (uninitialized constant ...::STRING_JOIN).
      it 'searches a relation that has a string join' do
        relation = Person.joins('INNER JOIN articles a457 ON a457.person_id = people.id')
        expected = relation.where(name: Person.first.name).distinct.pluck(:id)

        result = relation.ransack(name_eq: Person.first.name, articles_title_present: true).result
        expect { result.to_a }.not_to raise_error
        expect(result.distinct.pluck(:id)).to eq expected
      end

      # #375: a string join merged in from another relation was taken for an
      # association name ("Association named 'INNER JOIN ...' was not found").
      it 'searches a relation with a merged string join' do
        relation = Comment.joins(:article).merge(
          Article.joins('INNER JOIN people author ON author.id = articles.person_id')
                 .where(author: { id: Person.first.id })
        )

        result = relation.ransack(article_title_present: true).result
        expect(result.to_sql).to include('INNER JOIN people author')
        expect(result.to_a).to match_array(relation.to_a)
      end

      # #455: a relation carrying an Arel join node (as merging a
      # has_and_belongs_to_many association does) raised
      # ActiveRecord::ConfigurationError.
      it 'searches a relation that has an Arel join node' do
        people = Person.arel_table
        articles = Article.arel_table
        relation = Person.joins(people.join(articles).on(articles[:person_id].eq(people[:id])).join_sources)

        title = Article.where.not(person_id: nil).first.title
        result = relation.ransack(articles_title_eq: title).result
        expect { result.to_a }.not_to raise_error
        expect(result.distinct.pluck(:id)).to eq Person.joins(:articles).where(articles: { title: title }).distinct.pluck(:id)
      end
    end

    describe 'sorting' do
      # #63, #217: Ransack dropped an order applied before the search even
      # when the search had no sort of its own.
      it 'keeps the relation order when the search has no sort' do
        sql = Article.order(:title).ransack(title_cont: 'a').result.to_sql
        expect(sql).to include("ORDER BY #{col('articles', 'title')} ASC")
      end

      # #63: when the search does carry a sort, that sort takes precedence.
      it 'replaces the relation order with the search sort' do
        sql = Article.order(:title).ransack(s: 'id desc').result.to_sql
        expect(sql).to include("ORDER BY #{col('articles', 'id')} DESC")
        expect(sql).not_to include("#{col('articles', 'title')} ASC")
      end

      # #285: Ransack's ORDER BY could not be removed with `except(:order)`,
      # which pagination gems rely on when counting.
      it 'lets except(:order) remove the sort a search applied' do
        result = Article.ransack(s: 'title desc').result
        expect(result.to_sql).to match(/ORDER BY #{Regexp.escape(col('articles', 'title'))} DESC/)
        expect(result.except(:order).to_sql).not_to include('ORDER BY')
      end

      # #936: with the condition before the sort, a sort on an association the
      # relation already joins was bound to a non-existent alias
      # (people_comments.salary).
      it 'sorts by an association the relation already joins, whatever the param order' do
        title = 'issue-936-title'
        low = Comment.create!(article: Article.create!(title: "#{title} a"), person: Person.create!(salary: 1))
        high = Comment.create!(article: Article.create!(title: "#{title} b"), person: Person.create!(salary: 999_999))

        [
          { article_title_cont: title, s: 'person_salary desc' },
          { s: 'person_salary desc', article_title_cont: title }
        ].each do |params|
          relation = Comment.joins(:person).ransack(params).result
          expect(relation.to_sql).to include("ORDER BY #{col('people', 'salary')} DESC")
          expect(relation.to_a).to eq [high, low]
        end
      end
    end

    describe 'building a search' do
      # #73: creating a Search for an empty form queried the database.
      it 'runs no query until the result is asked for' do
        queries = []
        callback = lambda do |*, payload|
          queries << payload[:sql] unless payload[:name] == 'SCHEMA'
        end

        ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
          Search.new(Person)
          Person.ransack(name_cont: 'x', children_name_eq: 'y', s: 'name asc').inspect
        end

        expect(queries).to eq []
      end

      # #687: Rails 5 params[:q] is an ActionController::Parameters, not a
      # Hash; passing it unpermitted to a model with an allowlist must work
      # without calling to_unsafe_h first.
      it 'accepts unpermitted ActionController::Parameters for a model with an allowlist' do
        q = ::ActionController::Parameters.new(name_eq: 'x', s: 'name desc')
        sql = Person.ransack(q).result.to_sql
        expect(sql).to include("#{col('people', 'name')} = 'x'")
        expect(sql).to include("ORDER BY #{col('people', 'name')} DESC")
      end
    end

    # #343, #338, #276: a model backed by a database view raised
    # "No table named ... exists" as soon as a condition was added.
    describe 'a model backed by a database view' do
      before(:all) do
        ::ActiveRecord::Base.lease_connection.execute('CREATE VIEW issue_343_people AS SELECT id, name FROM people')
      end

      after(:all) do
        ::ActiveRecord::Base.lease_connection.execute('DROP VIEW IF EXISTS issue_343_people')
      end

      before do
        stub_const('Issue343Person', Class.new(ApplicationRecord) { self.table_name = 'issue_343_people' })
      end

      it 'searches and sorts its columns' do
        name = Person.first.name
        result = Issue343Person.ransack(name_eq: name, s: 'id desc').result

        expect(result.to_sql).to include("#{col('issue_343_people', 'name')} = ")
        expect(result.map(&:id)).to eq Person.unscoped.where(name: name).order(id: :desc).pluck(:id)
      end
    end

    describe Translate do
      # #289: an attribute translated only for the parent model was not used
      # for a subclass, though `human_attribute_name` finds it.
      it 'uses an attribute translation inherited from the parent model' do
        I18n.backend.store_translations(
          :issue_289,
          activerecord: { attributes: { article: { subject_header: 'Inherited Subject' } } }
        )

        I18n.with_locale(:issue_289) do
          expect(StoryArticle.human_attribute_name(:subject_header)).to eq 'Inherited Subject'
          expect(Translate.attribute(:subject_header, context: StoryArticle.ransack.context))
            .to eq 'Inherited Subject'
        end
      end
    end

    describe 'form helpers' do
      router = ActionDispatch::Routing::RouteSet.new
      router.draw { resources :people }
      include router.url_helpers

      before do
        @controller = ActionView::TestCase::TestController.new
        @controller.instance_variable_set(:@_routes, router)
        @controller.class_eval { include router.url_helpers }
        @controller.view_context_class.class_eval { include router.url_helpers }
      end

      def view = @controller.view_context

      def sort_fields_html(search)
        html = nil
        view.search_form_for(search) { |f| html = f.sort_fields { |s| yield(s) } }
        html.to_s
      end

      # #1365: a search key whose param was a string (`?q=abc`) made
      # sort_link raise "undefined method `merge' for String".
      it 'builds a sort_link when the search param is a string' do
        @controller.instance_variable_set(:@params, ActionController::Parameters.new({ 'q' => 'abc', controller: 'people' }))

        html = nil
        expect { html = view.sort_link(Person.ransack, :name) }.not_to raise_error
        expect(html).to match(/people\?q(%5B|\[)s(%5D|\])=name\+asc/)
        expect(html).not_to include('abc')
      end

      # #689 / #658: a field named after an alias came back empty after a
      # search, because the value was only stored under the expanded name.
      it 'redisplays the value searched under an alias' do
        search = Person.ransack(term_cont: 'Bob')
        expect(search.term_cont).to eq 'Bob'

        html = nil
        view.search_form_for(search) { |f| html = f.search_field(:term_cont) }
        expect(html).to include('value="Bob"')
      end

      # #518: form helpers other than search_form_for (simple_form, form_for)
      # ask the search for its model_name.
      it 'can pass a search to form_for, which reads its model_name' do
        search = Person.ransack(name_cont: 'Bob')
        expect(search.model_name.param_key).to eq 'q'

        html = view.form_for(search, url: '/people', method: :get) { |f| f.text_field(:name_cont) }
        expect(html).to include('name="q[name_cont]"')
        expect(html).to include('value="Bob"')
      end

      # #306: the direction select of a sort could not be rendered (and given
      # its own html options) apart from the attribute select.
      it 'renders the sort direction select on its own with its own html options' do
        html = sort_fields_html(Person.ransack(s: 'name desc')) { |s| s.sort_direction_select({}, class: 'direction') }

        expect(html).to include('name="q[s][0][dir]"')
        expect(html).to include('class="direction"')
        expect(html).to match(/<option value="asc">/)
        expect(html).to match(/<option selected="selected" value="desc">/)
        expect(html).not_to include('[name]')
      end

      # #248: the sort select offered only the base model's attributes, not
      # those of associations.
      it 'offers association attributes in the sort select' do
        html = sort_fields_html(Person.ransack(s: 'articles_title asc')) { |s| s.sort_select(associations: ['articles']) }

        expect(html).to match(/<option selected="selected" value="articles_title">/)
        expect(html).to match(/<optgroup label="Article">/)
      end

      # #189: sort_select renders nothing until a sort is built.
      it 'renders no sort select for a search with no sorts' do
        expect(sort_fields_html(Person.ransack) { |s| s.sort_select }).to eq ''
      end

      # #189: after build_sort it renders the attribute and direction selects.
      it 'renders name and dir selects after build_sort' do
        search = Person.ransack
        search.build_sort
        html = sort_fields_html(search) { |s| s.sort_select }
        expect(html).to include('name="q[s][0][name]"')
        expect(html).to include('name="q[s][0][dir]"')
        expect(html).to include('<option value="name">')
      end

      # #87: used inside sort_fields, sort_select reflects the current sort.
      it 'selects the attribute and direction of the current sort' do
        html = sort_fields_html(Person.ransack(s: 'name desc')) { |s| s.sort_select }
        expect(html).to include('<option selected="selected" value="name">')
        expect(html).to include('<option selected="selected" value="desc">')
      end
    end
  end
end
