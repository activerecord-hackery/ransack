require 'spec_helper'

module Ransack
  module Helpers
    describe FormHelper do

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
      end

      describe '#sort_link' do
        subject { @controller.view_context.sort_link(Person.search(:sorts => ['name desc']), :name, :controller => 'people') }

        it { should match /people\?q%5Bs%5D=name\+asc/}
        it { should match /sort_link desc/}
        it { should match /Full Name &#9660;/}
      end

    end
  end
end