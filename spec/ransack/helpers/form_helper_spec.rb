require 'spec_helper'

module Ransack
  module Helpers
    describe FormHelper do

      router = ActionDispatch::Routing::RouteSet.new
      router.draw do
        resources :people
        get ':controller(/:action(/:id(.:format)))'
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

      describe '#sort_link with default search_key' do
        subject { @controller.view_context.sort_link([:main_app, Person.search(:sorts => ['name desc'])], :name, :controller => 'people') }
        it { should match /people\?q(%5B|\[)s(%5D|\])=name\+asc/ }
        it { should match /sort_link desc/ }
        it { should match /Full Name &#9660;/ }
      end

      describe '#sort_link with default search_key defined as symbol' do
        subject { @controller.view_context.sort_link(Person.search({:sorts => ['name desc']}, :search_key => :people_search),
                                                     :name, :controller => 'people') }

        it { should match /people\?people_search(%5B|\[)s(%5D|\])=name\+asc/ }
      end

      describe '#sort_link with default search_key defined as string' do
        subject { @controller.view_context.sort_link(Person.search({:sorts => ['name desc']}, :search_key => 'people_search'),
                                                       :name, :controller => 'people') }

        it { should match /people\?people_search(%5B|\[)s(%5D|\])=name\+asc/ }
      end
    end
  end
end
