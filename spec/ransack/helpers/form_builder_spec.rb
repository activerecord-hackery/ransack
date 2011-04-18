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
        html = @f.datetime_select :created_at_eq
        [2011, 1, 2, 3, 4, 5].each do |val|
          html.should match /<option selected="selected" value="#{val}">#{val}<\/option>/o
        end
      end

    end
  end
end