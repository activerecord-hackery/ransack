require 'spec_helper'

module Ransack
  describe Predicate do

    before do
      @s = Search.new(Person)
    end

    describe 'cont' do
      it 'generates a LIKE query with value surrounded by %' do
        @s.name_cont = 'ric'
        @s.result.to_sql.should match /"people"."name" LIKE '%ric%'/
      end
    end

    describe 'not_cont' do
      it 'generates a NOT LIKE query with value surrounded by %' do
        @s.name_not_cont = 'ric'
        @s.result.to_sql.should match /"people"."name" NOT LIKE '%ric%'/
      end
    end

  end
end