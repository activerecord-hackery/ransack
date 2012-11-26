require 'spec_helper'

module Ransack
  describe Predicate do

    before do
      @s = Search.new(Person)
    end

    describe 'eq' do
      it 'generates an equality condition for boolean true' do
        @s.awesome_eq = true
        @s.result.to_sql.should match /"people"."awesome" = 't'/
      end

      it 'generates an equality condition for boolean false' do
        @s.awesome_eq = false
        @s.result.to_sql.should match /"people"."awesome" = 'f'/
      end

      it 'does not generate a condition for nil' do
        @s.awesome_eq = nil
        @s.result.to_sql.should_not match /WHERE/
      end
    end

    describe 'cont' do
      it 'generates a LIKE query with value surrounded by %' do
        @s.name_cont = 'ric'
        @s.result.to_sql.should match /"people"."name" LIKE '%ric%'/
      end
      it 'escapes %, _ and \\ in value' do
        @s.name_cont = '%_\\'
        @s.result.to_sql.should match /"people"."name" LIKE '%\\%\\_\\\\%'/
      end
    end

    describe 'not_cont' do
      it 'generates a NOT LIKE query with value surrounded by %' do
        @s.name_not_cont = 'ric'
        @s.result.to_sql.should match /"people"."name" NOT LIKE '%ric%'/
      end
    end

    describe 'null' do
      it 'generates a value IS NULL query' do
        @s.name_null = true
        @s.result.to_sql.should match /"people"."name" IS NULL/
      end
    end

    describe 'not_null' do
      it 'generates a value IS NOT NULL query' do
        @s.name_not_null = true
        @s.result.to_sql.should match /"people"."name" IS NOT NULL/
      end
    end
  end
end
