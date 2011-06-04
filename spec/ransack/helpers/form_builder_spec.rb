require 'spec_helper'

module Ransack
  module Helpers
    describe FormBuilder do

      router = ActionDispatch::Routing::RouteSet.new
      router.draw do
        resources :people
        match ':controller(/:action(/:id(.:format)))'
      end

      include router.url_helpers

      # FIXME: figure out a cleaner way to get this behavior
      before do
        @controller = ActionView::TestCase::TestController.new
        @controller.instance_variable_set(:@_routes, router)
        @controller.class_eval do
          include router.url_helpers
        end

        @controller.view_context_class.class_eval do
          include router.url_helpers
        end

        @s = Person.search
        @controller.view_context.search_form_for @s do |f|
          @f = f
        end
      end

      it 'selects previously-entered time values with datetime_select' do
        @s.created_at_eq = [2011, 1, 2, 3, 4, 5]
        html = @f.datetime_select :created_at_eq, :use_month_numbers => true, :include_seconds => true
        %w(2011 1 2 03 04 05).each do |val|
          html.should match /<option selected="selected" value="#{val}">#{val}<\/option>/
        end
      end

      it 'localizes labels' do
        html = @f.label :name_cont
        html.should match /Full Name contains/
      end

      it 'localizes submit' do
        html = @f.submit
        html.should match /"Search"/
      end

      it 'returns ransackable attributes for attribute_select' do
        html = @f.attribute_select
        html.split(/\n/).should have(Person.ransackable_attributes.size + 1).lines
        Person.ransackable_attributes.each do |attribute|
          html.should match /<option value="#{attribute}">/
        end
      end

      it 'returns ransackable attributes for associations in attribute_select with associations' do
        attributes = Person.ransackable_attributes + Article.ransackable_attributes.map {|a| "articles_#{a}"}
        html = @f.attribute_select :associations => ['articles']
        html.split(/\n/).should have(attributes.size).lines
        attributes.each do |attribute|
          html.should match /<option value="#{attribute}">/
        end
      end

      it 'returns option groups for base and associations in attribute_select with associations' do
        html = @f.attribute_select :associations => ['articles']
        [Person, Article].each do |model|
          html.should match /<optgroup label="#{model}">/
        end
      end

    end
  end
end