require 'spec_helper'

module Ransack
  module Helpers
    describe FormHelper do

      router = ActionDispatch::Routing::RouteSet.new
      router.draw do
        resources :people, :notes
        namespace :admin do
          resources :comments
        end
      end

      include router.url_helpers

      # FIXME: figure out a cleaner way to get this behavior
      before do
        @controller = ActionView::TestCase::TestController.new
        @controller.instance_variable_set(:@_routes, router)
        @controller.class_eval { include router.url_helpers }
        @controller.view_context_class.class_eval { include router.url_helpers }
      end

      describe '#sort_link with default search_key' do
        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.search(sorts: ['name desc'])],
            :name,
            controller: 'people'
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
        it { should match /sort_link desc/ }
        it { should match /Full Name&nbsp;&#9660;/ }
      end

      describe '#sort_url with default search_key' do
        subject { @controller.view_context
          .sort_url(
            [:main_app, Person.search(sorts: ['name desc'])],
            :name,
            controller: 'people'
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
      end

      describe '#sort_link with default search_key defined as symbol' do
        subject { @controller.view_context
          .sort_link(
            Person.search({ sorts: ['name desc'] }, search_key: :people_search),
            :name, controller: 'people'
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

      describe '#sort_url with default search_key defined as symbol' do
        subject { @controller.view_context
          .sort_url(
            Person.search({ sorts: ['name desc'] }, search_key: :people_search),
            :name, controller: 'people'
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

      describe '#sort_link desc through association table defined as symbol' do
        subject { @controller.view_context
          .sort_link(
            Person.search({ sorts: 'comments_body asc' }),
            :comments_body,
            controller: 'people'
          )
        }
        it {
          should match(
            if ActiveRecord::VERSION::STRING =~ /^3\.[1-2]\./
              /people\?q%5Bs%5D=comments.body\+desc/
            else
              /people\?q(%5B|\[)s(%5D|\])=comments.body\+desc/
            end
            )
          }
        it { should match /sort_link asc/ }
        it { should match /Body&nbsp;&#9650;/ }
      end

      describe '#sort_url desc through association table defined as symbol' do
        subject { @controller.view_context
          .sort_url(
            Person.search({ sorts: 'comments_body asc' }),
            :comments_body,
            controller: 'people'
          )
        }
        it {
          should match(
            if ActiveRecord::VERSION::STRING =~ /^3\.[1-2]\./
              /people\?q%5Bs%5D=comments.body\+desc/
            else
              /people\?q(%5B|\[)s(%5D|\])=comments.body\+desc/
            end
          )
        }
      end

      describe '#sort_link through association table defined as a string' do
        subject { @controller.view_context
          .sort_link(
            Person.search({ sorts: 'comments.body desc' }),
            'comments.body',
            controller: 'people'
          )
        }
        it {
          should match(
            if ActiveRecord::VERSION::STRING =~ /^3\.[1-2]\./
              /people\?q%5Bs%5D=comments.body\+asc/
            else
              /people\?q(%5B|\[)s(%5D|\])=comments.body\+asc/
            end
            )
          }
        it { should match /sort_link desc/ }
        it { should match /Comments.body&nbsp;&#9660;/ }
      end

      describe '#sort_url through association table defined as a string' do
        subject { @controller.view_context
          .sort_url(
            Person.search({ sorts: 'comments.body desc' }),
            'comments.body',
            controller: 'people'
          )
        }
        it {
          should match(
            if ActiveRecord::VERSION::STRING =~ /^3\.[1-2]\./
              /people\?q%5Bs%5D=comments.body\+asc/
            else
              /people\?q(%5B|\[)s(%5D|\])=comments.body\+asc/
            end
          )
        }
      end

      describe '#sort_link works even if search params are a blank string' do
        before { @controller.view_context.params[:q] = '' }
        specify {
          expect { @controller.view_context
            .sort_link(
              Person.search(@controller.view_context.params[:q]),
              :name,
              controller: 'people'
            )
          }.not_to raise_error
        }
      end

      describe '#sort_url works even if search params are a blank string' do
        before { @controller.view_context.params[:q] = '' }
        specify {
          expect { @controller.view_context
            .sort_url(
              Person.search(@controller.view_context.params[:q]),
              :name,
              controller: 'people'
            )
          }.not_to raise_error
        }
      end

      describe '#sort_link with search_key defined as a string' do
        subject { @controller.view_context
          .sort_link(
            Person.search(
              { sorts: ['name desc'] }, search_key: 'people_search'
            ),
            :name,
            controller: 'people'
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

      describe '#sort_link with default_order defined with a string key' do
        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.search()],
            :name,
            controller: 'people',
            default_order: 'desc'
          )
        }
        it { should_not match /default_order/ }
      end

      describe '#sort_url with default_order defined with a string key' do
        subject { @controller.view_context
          .sort_url(
            [:main_app, Person.search()],
            :name,
            controller: 'people',
            default_order: 'desc'
          )
        }
        it { should_not match /default_order/ }
      end

      describe '#sort_link with multiple search_keys defined as an array' do
        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.search(sorts: ['name desc', 'email asc'])],
            :name, [:name, 'email DESC'],
            controller: 'people'
          )
        }
        it {
          should match(            /people\?q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=name\+asc&amp;q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=email\+desc/
          )
        }
        it { should match /sort_link desc/ }
        it { should match /Full Name&nbsp;&#9660;/ }
      end

      describe '#sort_url with multiple search_keys defined as an array' do
        subject { @controller.view_context
          .sort_url(
            [:main_app, Person.search(sorts: ['name desc', 'email asc'])],
            :name, [:name, 'email DESC'],
            controller: 'people'
          )
        }
        it {
          should match( /people\?q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=name\+asc&q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=email\+desc/
          )
        }
      end

      describe '#sort_link with multiple search_keys does not break on nil values & ignores them' do
        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.search(sorts: ['name desc', nil, 'email', nil])],
            :name, [nil, :name, nil, 'email DESC', nil],
            controller: 'people'
          )
        }
        it {
          should match(         /people\?q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=name\+asc&amp;q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=email\+desc/
          )
        }
        it { should match /sort_link desc/ }
        it { should match /Full Name&nbsp;&#9660;/ }
      end

      describe '#sort_url with multiple search_keys does not break on nil values & ignores them' do
        subject { @controller.view_context
          .sort_url(
            [:main_app, Person.search(sorts: ['name desc', nil, 'email', nil])],
            :name, [nil, :name, nil, 'email DESC', nil],
            controller: 'people'
          )
        }
        it {
          should match(                     /people\?q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=name\+asc&q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=email\+desc/
          )
        }
      end

      describe '#sort_link with multiple search_keys should allow a label to be specified' do
        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.search(sorts: ['name desc', 'email asc'])],
            :name, [:name, 'email DESC'],
            'Property Name',
            controller: 'people'
          )
        }
        it { should match /Property Name&nbsp;&#9660;/ }
      end

      describe '#sort_link with multiple search_keys should flip multiple fields specified without a direction' do
        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.search(sorts: ['name desc', 'email asc'])],
            :name, [:name, :email],
            controller: 'people'
          )
        }
        it {
          should match(          /people\?q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=name\+asc&amp;q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=email\+desc/
          )
        }
        it { should match /sort_link desc/ }
        it { should match /Full Name&nbsp;&#9660;/ }
      end

      describe '#sort_url with multiple search_keys should flip multiple fields specified without a direction' do
        subject { @controller.view_context
          .sort_url(
            [:main_app, Person.search(sorts: ['name desc', 'email asc'])],
            :name, [:name, :email],
            controller: 'people'
          )
        }
        it {
          should match(                /people\?q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=name\+asc&q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=email\+desc/
          )
        }
      end

      describe '#sort_link with multiple search_keys and default_order specified as a string' do
        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.search()],
            :name, [:name, :email],
            controller: 'people',
            default_order: 'desc'
          )
        }
        it {
          should match(            /people\?q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=name\+desc&amp;q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=email\+desc/
          )
        }
        it { should match /sort_link/ }
        it { should match /Full Name/ }
      end

      describe '#sort_url with multiple search_keys and default_order specified as a string' do
        subject { @controller.view_context
          .sort_url(
            [:main_app, Person.search()],
            :name, [:name, :email],
            controller: 'people',
            default_order: 'desc'
          )
        }
        it {
          should match(                     /people\?q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=name\+desc&q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=email\+desc/
          )
        }
      end

      describe '#sort_link with multiple search_keys and default_order specified as a symbol' do
        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.search()],
            :name, [:name, :email],
            controller: 'people',
            default_order: :desc
          )
        }
        it {
          should match(            /people\?q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=name\+desc&amp;q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=email\+desc/
          )
        }
        it { should match /sort_link/ }
        it { should match /Full Name/ }
      end

      describe '#sort_url with multiple search_keys and default_order specified as a symbol' do
        subject { @controller.view_context
          .sort_url(
            [:main_app, Person.search()],
            :name, [:name, :email],
            controller: 'people',
            default_order: :desc
          )
        }
        it {
          should match(                     /people\?q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=name\+desc&q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=email\+desc/
          )
        }
      end

      describe '#sort_link with multiple search_keys should allow multiple default_orders to be specified' do
        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.search()],
            :name, [:name, :email],
            controller: 'people',
            default_order: { name: 'desc', email: 'asc' }
          )
        }
        it {
          should match(      /people\?q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=name\+desc&amp;q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=email\+asc/
          )
        }
        it { should match /sort_link/ }
        it { should match /Full Name/ }
      end

      describe '#sort_url with multiple search_keys should allow multiple default_orders to be specified' do
        subject { @controller.view_context
          .sort_url(
            [:main_app, Person.search()],
            :name, [:name, :email],
            controller: 'people',
            default_order: { name: 'desc', email: 'asc' }
          )
        }
        it {
          should match(                     /people\?q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=name\+desc&q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=email\+asc/
          )
        }
      end

      describe '#sort_link with multiple search_keys with multiple default_orders should not override a specified order' do
        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.search()],
            :name, [:name, 'email desc'],
            controller: 'people',
            default_order: { name: 'desc', email: 'asc' }
          )
        }
        it {
          should match(  /people\?q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=name\+desc&amp;q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=email\+desc/
          )
        }
        it { should match /sort_link/ }
        it { should match /Full Name/ }
      end

      describe '#sort_url with multiple search_keys with multiple default_orders should not override a specified order' do
        subject { @controller.view_context
          .sort_url(
            [:main_app, Person.search()],
            :name, [:name, 'email desc'],
            controller: 'people',
            default_order: { name: 'desc', email: 'asc' }
          )
        }
        it {
          should match(        /people\?q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=name\+desc&q(%5B|\[)s(%5D|\])(%5B|\[)(%5D|\])=email\+desc/
          )
        }
      end

      describe "#sort_link on polymorphic association should preserve association model name case" do
        subject { @controller.view_context
          .sort_link(
            [:main_app, Note.search()],
            :notable_of_Person_type_name, "Notable",
            controller: 'notes'
          )
        }
        it {
          should match(
            if ActiveRecord::VERSION::STRING =~ /^3\.[1-2]\./
              /notes\?q%5Bs%5D=notable_of_Person_type_name\+asc/
            else
              /notes\?q(%5B|\[)s(%5D|\])=notable_of_Person_type_name\+asc/
            end
          )
        }
        it { should match /sort_link/ }
        it { should match /Notable/ }
      end

      describe "#sort_url on polymorphic association should preserve association model name case" do
        subject { @controller.view_context
          .sort_link(
            [:main_app, Note.search()],
            :notable_of_Person_type_name, "Notable",
            controller: 'notes'
          )
        }
        it {
          should match(
            if ActiveRecord::VERSION::STRING =~ /^3\.[1-2]\./
              /notes\?q%5Bs%5D=notable_of_Person_type_name\+asc/
            else
              /notes\?q(%5B|\[)s(%5D|\])=notable_of_Person_type_name\+asc/
            end
          )
        }
      end

      context 'view has existing parameters' do

        describe '#sort_link should not remove existing params' do

          before { @controller.view_context.params[:exist] = 'existing' }

          subject {
            @controller.view_context.sort_link(
              Person.search(
                { sorts: ['name desc'] },
                search_key: 'people_search'
              ),
              :name,
              controller: 'people'
            )
          }

          it { should match /exist\=existing/ }
        end

        describe '#sort_url should not remove existing params' do

          before { @controller.view_context.params[:exist] = 'existing' }

          subject {
            @controller.view_context.sort_url(
              Person.search(
                { sorts: ['name desc'] },
                search_key: 'people_search'
              ),
              :name,
              controller: 'people'
            )
          }

          it { should match /exist\=existing/ }
        end

        context 'using a real ActionController::Parameter object',
          if: ::ActiveRecord::VERSION::MAJOR > 3 do

          describe 'with symbol q:, #sort_link should include search params' do
            subject { @controller.view_context.sort_link(Person.search, :name) }
            let(:params) { ActionController::Parameters.new(
              { :q => { name_eq: 'TEST' }, controller: 'people' }
              ) }
            before { @controller.instance_variable_set(:@params, params) }

            it {
              should match(
                /people\?q(%5B|\[)name_eq(%5D|\])=TEST&amp;q(%5B|\[)s(%5D|\])
                =name\+asc/x,
              )
            }
          end

          describe 'with symbol q:, #sort_url should include search params' do
            subject { @controller.view_context.sort_url(Person.search, :name) }
            let(:params) { ActionController::Parameters.new(
              { :q => { name_eq: 'TEST' }, controller: 'people' }
              ) }
            before { @controller.instance_variable_set(:@params, params) }

            it {
              should match(
                /people\?q(%5B|\[)name_eq(%5D|\])=TEST&q(%5B|\[)s(%5D|\])
                =name\+asc/x,
              )
            }
          end

          describe "with string 'q', #sort_link should include search params" do
            subject { @controller.view_context.sort_link(Person.search, :name) }
            let(:params) {
              ActionController::Parameters.new(
                { 'q' => { name_eq: 'Test2' }, controller: 'people' }
                ) }
            before { @controller.instance_variable_set(:@params, params) }

            it {
              should match(
                /people\?q(%5B|\[)name_eq(%5D|\])=Test2&amp;q(%5B|\[)s(%5D|\])
                =name\+asc/x,
              )
            }
          end

          describe "with string 'q', #sort_url should include search params" do
            subject { @controller.view_context.sort_url(Person.search, :name) }
            let(:params) {
              ActionController::Parameters.new(
                { 'q' => { name_eq: 'Test2' }, controller: 'people' }
                ) }
            before { @controller.instance_variable_set(:@params, params) }

            it {
              should match(
                /people\?q(%5B|\[)name_eq(%5D|\])=Test2&q(%5B|\[)s(%5D|\])
                =name\+asc/x,
              )
            }
          end
        end
      end

      describe '#sort_link with hide order indicator set to true' do
        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.search(sorts: ['name desc'])],
            :name,
            controller: 'people',
            hide_indicator: true
          )
        }
        it { should match /Full Name/ }
        it { should_not match /&#9660;|&#9650;/ }
      end

      describe '#sort_link with hide order indicator set to false' do
        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.search(sorts: ['name desc'])],
            :name,
            controller: 'people',
            hide_indicator: false
          )
        }
        it { should match /Full Name&nbsp;&#9660;/ }
      end

      describe '#sort_link with config set with custom up_arrow' do
        before do
          Ransack.configure do |c|
            c.custom_arrows = { up_arrow: "\u{1F446}" }
          end
        end
        after do
          #set back to default
          Ransack.configure do |c|
            c.custom_arrows = { up_arrow: "&#9660;" }
          end
        end
        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.search(sorts: ['name desc'])],
            :name,
            controller: 'people',
            hide_indicator: false
          )
        }
        it { should match /Full Name&nbsp;\u{1F446}/ }
      end

      describe '#sort_link with config set with custom down_arrow' do
        before do
          Ransack.configure do |c|
            c.custom_arrows = { down_arrow: "\u{1F447}" }
          end
        end
        after do
          #set back to default
          Ransack.configure do |c|
            c.custom_arrows = { down_arrow: "&#9650;" }
          end
        end
        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.search(sorts: ['name asc'])],
            :name,
            controller: 'people',
            hide_indicator: false
          )
        }
        it { should match /Full Name&nbsp;\u{1F447}/ }
      end

      describe '#sort_link with config set to globally hide order indicators' do
        before do
          Ransack.configure { |c| c.hide_sort_order_indicators = true }
        end
        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.search(sorts: ['name desc'])],
            :name,
            controller: 'people'
          )
        }
        it { should_not match /&#9660;|&#9650;/ }
      end

      describe '#sort_link with config set to globally show order indicators' do
        before do
          Ransack.configure { |c| c.hide_sort_order_indicators = false }
        end
        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.search(sorts: ['name desc'])],
            :name,
            controller: 'people'
          )
        }
        it { should match /Full Name&nbsp;&#9660;/ }
      end

      describe '#sort_link with a block' do
        subject { @controller.view_context
          .sort_link(
            [:main_app, Person.search(sorts: ['name desc'])],
            :name,
            controller: 'people'
          ) { 'Block label' }
        }
        it { should match /Block label&nbsp;&#9660;/ }
      end

      describe '#search_form_for with default format' do
        subject { @controller.view_context
          .search_form_for(Person.search) {} }
        it { should match /action="\/people"/ }
      end

      describe '#search_form_for with pdf format' do
        subject {
          @controller.view_context
          .search_form_for(Person.search, format: :pdf) {}
        }
        it { should match /action="\/people.pdf"/ }
      end

      describe '#search_form_for with json format' do
        subject {
          @controller.view_context
          .search_form_for(Person.search, format: :json) {}
        }
        it { should match /action="\/people.json"/ }
      end

      describe '#search_form_for with an array of routes' do
        subject {
          @controller.view_context
          .search_form_for([:admin, Comment.search]) {}
        }
        it { should match /action="\/admin\/comments"/ }
      end

      describe '#search_form_for with custom default search key' do
        before do
          Ransack.configure { |c| c.search_key = :example }
        end
        subject {
          @controller.view_context
          .search_form_for(Person.search) { |f| f.text_field :name_eq }
        }
        it { should match /example_name_eq/ }
      end
    end
  end
end
