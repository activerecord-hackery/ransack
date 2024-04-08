require 'spec_helper'

module Ransack
  module Helpers
    describe SimpleFormBuilder do

      router = ActionDispatch::Routing::RouteSet.new
      router.draw do
        resources :people, :comments, :notes
      end

      include router.url_helpers

      # FIXME: figure out a cleaner way to get this behavior
      before do
        @controller = ActionView::TestCase::TestController.new
        @controller.instance_variable_set(:@_routes, router)
        @controller.class_eval { include router.url_helpers }
        @controller.view_context_class.class_eval { include router.url_helpers }
        @s = Person.ransack
        @controller.view_context.search_simple_form_for(@s) { |f| @f = f }
      end

      describe "#input (from SimpleForm)" do
        context "with :name_cont predicate" do
          subject { @f.input(:name_cont) }

          it "should generate a wrapping div with both label and input inside" do
            expect(subject).to match(/<div.*?><label.*?<\/label>.*?<input.*?\/>.*?<\/div>/)
          end

          it "the wrapping div should have class 'q_name_cont'" do
            expect(subject).to match(/<div.*?class=".*?q_name_cont.*?".*?>/)
          end

          it "should generate correct label text with predicate from locale files" do
            expect(subject).to match(/<label.*?>.*?Full Name contains.*?<\/label>/)
          end

          it "should generate correct input name=\"q[name_cont]\"" do
            expect(subject).to match(/<input.*?name="q\[name_cont\]".*?\/>/)
          end

          it "should generate correct input id=\"q_name_cont\"" do
            expect(subject).to match(/<input.*?id="q_name_cont".*?\/>/)
          end

          it "should generate correct input type=\"text\"" do
            expect(subject).to match(/<input.*?type="text".*?\/>/)
          end
        end
      end
    end
  end
end
