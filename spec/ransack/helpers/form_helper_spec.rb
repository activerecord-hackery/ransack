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
        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.search(:sorts => ['name desc'])],
            :name,
            :controller => 'people'
          )
        }
        it {
          should match(
            if ActiveRecord::VERSION::STRING =~ /^3\.[1-2]\./
              /people\?q%5Bs%5D=name\+asc/
            else
              /people\?q(%5B|\[)s(%5D|\])=name\+asc/
            end
          )
        }
        it {
          should match /sort_link desc/
        }
        it {
          should match /Full Name&nbsp;&#9660;/
        }
      end

      describe '#sort_link with default search_key defined as symbol' do
        subject { @controller.
          view_context.sort_link(
            Person.search(
              { :sorts => ['name desc'] }, :search_key => :people_search
              ),
            :name,
            :controller => 'people'
          )
        }
        it {
          should match(
            if ActiveRecord::VERSION::STRING =~ /^3\.[1-2]\./
              /people\?people_search%5Bs%5D=name\+asc/
            else
              /people\?people_search(%5B|\[)s(%5D|\])=name\+asc/
            end
          )
        }
      end

      describe '#sort_link works even if search params are a blank string' do
        before { @controller.view_context.params[:q] = '' }
        specify {
          expect {
            @controller.view_context.sort_link(
              Person.search(@controller.view_context.params[:q]),
              :name,
              :controller => 'people'
            )
          }.not_to raise_error
        }
      end

      describe '#sort_link with default search_key defined as string' do
        subject {
          @controller.view_context.sort_link(
            Person.search(
              { :sorts => ['name desc'] }, :search_key => 'people_search'
              ),
            :name,
            :controller => 'people'
          )
        }
        it {
          should match(
            if ActiveRecord::VERSION::STRING =~ /^3\.[1-2]\./
              /people\?people_search%5Bs%5D=name\+asc/
            else
              /people\?people_search(%5B|\[)s(%5D|\])=name\+asc/
            end
          )
        }
      end

      context 'view has existing parameters' do
        before do
          @controller.view_context.params.merge!({ :exist => 'existing' })
        end
        describe '#sort_link should not remove existing params' do
          subject {
            @controller.view_context.sort_link(
              Person.search(
                { :sorts => ['name desc'] }, :search_key => 'people_search'
                ),
              :name,
              :controller => 'people'
            )
          }
          it {
            should match /exist\=existing/
          }
        end
      end

      describe '#search_form_for with default format' do
        subject {
          @controller.view_context
          .search_form_for(Person.search) {}
        }
        it {
          should match /action="\/people"/
        }
      end

      describe '#search_form_for with pdf format' do
        subject {
          @controller.view_context
          .search_form_for(Person.search, :format => :pdf) {}
        }
        it {
          should match /action="\/people.pdf"/
        }
      end

      describe '#search_form_for with json format' do
        subject {
          @controller.view_context
          .search_form_for(Person.search, :format => :json) {}
        }
        it {
          should match /action="\/people.json"/
        }
      end

    end
  end
end
