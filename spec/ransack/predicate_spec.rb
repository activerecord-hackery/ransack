require 'spec_helper'

module Ransack
  describe Predicate do

    before do
      @s = Search.new(Person)
    end

    shared_examples 'wildcard escaping' do |method, regexp|
      it 'automatically converts integers to strings' do
        subject.parent_id_cont = 1
        expect { subject.result }.to_not raise_error
      end

      it "escapes '%', '.' and '\\\\' in value" do
        subject.send(:"#{method}=", '%._\\')
        subject.result.to_sql.should match(regexp)
      end
    end

    describe 'eq' do
      it 'generates an equality condition for boolean true' do
        @s.awesome_eq = true
        field = "#{quote_table_name("people")}.#{
          quote_column_name("awesome")}"
        @s.result.to_sql.should match /#{field} = #{
          ActiveRecord::Base.connection.quoted_true}/
      end

      it 'generates an equality condition for boolean false' do
        @s.awesome_eq = false
        field = "#{quote_table_name("people")}.#{quote_column_name("awesome")}"
        @s.result.to_sql.should match /#{field} = #{
          ActiveRecord::Base.connection.quoted_false}/
      end

      it 'does not generate a condition for nil' do
        @s.awesome_eq = nil
        @s.result.to_sql.should_not match /WHERE/
      end
    end

    describe 'cont' do
  
      it_has_behavior 'wildcard escaping', :name_cont,
        (if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
          /"people"."name" ILIKE '%\\%\\._\\\\%'/
        elsif ActiveRecord::Base.connection.adapter_name == "Mysql2"
          /`people`.`name` LIKE '%\\\\%\\\\._\\\\\\\\%'/
        else
         /"people"."name" LIKE '%%._\\%'/
        end) do
        subject { @s }
      end

      it 'generates a LIKE query with value surrounded by %' do
        @s.name_cont = 'ric'
        field = "#{quote_table_name("people")}.#{quote_column_name("name")}"
        @s.result.to_sql.should match /#{field} I?LIKE '%ric%'/
      end
    end

    describe 'not_cont' do
      it_has_behavior 'wildcard escaping', :name_not_cont,
        (if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
          /"people"."name" NOT ILIKE '%\\%\\._\\\\%'/
        elsif ActiveRecord::Base.connection.adapter_name == "Mysql2"
          /`people`.`name` NOT LIKE '%\\\\%\\\\._\\\\\\\\%'/
        else
         /"people"."name" NOT LIKE '%%._\\%'/
        end) do
        subject { @s }
      end

      it 'generates a NOT LIKE query with value surrounded by %' do
        @s.name_not_cont = 'ric'
        field = "#{quote_table_name("people")}.#{quote_column_name("name")}"
        @s.result.to_sql.should match /#{field} NOT I?LIKE '%ric%'/
      end
    end

    describe 'null' do
      it 'generates a value IS NULL query' do
        @s.name_null = true
        field = "#{quote_table_name("people")}.#{quote_column_name("name")}"
        @s.result.to_sql.should match /#{field} IS NULL/
      end
    end

    describe 'not_null' do
      it 'generates a value IS NOT NULL query' do
        @s.name_not_null = true
        field = "#{quote_table_name("people")}.#{quote_column_name("name")}"
        @s.result.to_sql.should match /#{field} IS NOT NULL/
      end
    end
  end
end
