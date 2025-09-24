require File.dirname(__FILE__) + '/spec_helper'
require 'machinist/active_record'
require 'active_support/whiny_nil'

module MachinistActiveRecordSpecs
  
  class Person < ActiveRecord::Base
    attr_protected :password
  end

  class Admin < Person
  end

  class Post < ActiveRecord::Base
    has_many :comments
  end

  class Comment < ActiveRecord::Base
    belongs_to :post
    belongs_to :author, :class_name => "Person"
  end

  describe Machinist, "ActiveRecord adapter" do
    before(:suite) do
      ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/log/test.log")
      ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
      load(File.dirname(__FILE__) + "/db/schema.rb")
    end
  
    before(:each) do
      [Person, Admin, Post, Comment].each(&:clear_blueprints!)
    end
  
    describe "make method" do
      it "should support single-table inheritance" do
        Person.blueprint { }
        Admin.blueprint  { }
        admin = Admin.make
        admin.should_not be_new_record
        admin.type.should == "Admin"
      end

      it "should save the constructed object" do
        Person.blueprint { }
        person = Person.make
        person.should_not be_new_record
      end
  
      it "should create an object through belongs_to association" do
        Post.blueprint { }
        Comment.blueprint { post }
        Comment.make.post.class.should == Post
      end
  
      it "should create an object through belongs_to association with a class_name attribute" do
        Person.blueprint { }
        Comment.blueprint { author }
        Comment.make.author.class.should == Person
      end

      it "should create an object through belongs_to association using a named blueprint" do
        Post.blueprint { }
        Post.blueprint(:dummy) { title 'Dummy Post' }
        Comment.blueprint { post(:dummy) }
        Comment.make.post.title.should == 'Dummy Post'
      end
      
      it "should allow creating an object through a has_many association" do
        Post.blueprint do
          comments { [Comment.make] }
        end
        Comment.blueprint { }
        Post.make.comments.should have(1).instance_of(Comment)
      end
      
      it "should allow setting a protected attribute in the blueprint" do
        Person.blueprint do
          password "Test"
        end
        Person.make.password.should == "Test"
      end
      
      it "should allow overriding a protected attribute" do
        Person.blueprint do
          password "Test"
        end
        Person.make(:password => "New").password.should == "New"
      end
      
      it "should allow setting the id attribute in a blueprint" do
        Person.blueprint { id 12345 }
        Person.make.id.should == 12345
      end
      
      it "should allow setting the type attribute in a blueprint" do
        Person.blueprint { type "Person" }
        Person.make.type.should == "Person"
      end

      describe "on a has_many association" do
        before do 
          Post.blueprint { }
          Comment.blueprint { post }
          @post = Post.make
          @comment = @post.comments.make
        end
    
        it "should save the created object" do
          @comment.should_not be_new_record
        end
    
        it "should set the parent association on the created object" do
          @comment.post.should == @post
        end
      end
    end

    describe "plan method" do
      it "should not save the constructed object" do
        person_count = Person.count
        Person.blueprint { }
        person = Person.plan
        Person.count.should == person_count
      end
  
      it "should create an object through a belongs_to association, and return its id" do
        Post.blueprint { }
        Comment.blueprint { post }
        post_count = Post.count
        comment = Comment.plan
        Post.count.should == post_count + 1
        comment[:post].should be_nil
        comment[:post_id].should_not be_nil
      end

      describe "on a belongs_to association" do
        it "should allow explicitly setting the association to nil" do
          Comment.blueprint { post }
          Comment.blueprint(:no_post) { post { nil } }
          lambda {
            @comment = Comment.plan(:no_post)
          }.should_not raise_error
        end
      end
  
      describe "on a has_many association" do
        before do
          Post.blueprint { }
          Comment.blueprint do
            post
            body { "Test" }
          end
          @post = Post.make
          @post_count = Post.count
          @comment = @post.comments.plan
        end
    
        it "should not include the parent in the returned hash" do
          @comment[:post].should be_nil
          @comment[:post_id].should be_nil
        end
    
        it "should not create an extra parent object" do
          Post.count.should == @post_count
        end
      end
    end

    describe "make_unsaved method" do
      it "should not save the constructed object" do
        Person.blueprint { }
        person = Person.make_unsaved
        person.should be_new_record
      end
  
      it "should not save associated objects" do
        Post.blueprint { }
        Comment.blueprint { post }
        comment = Comment.make_unsaved
        comment.post.should be_new_record
      end
  
      it "should save objects made within a passed-in block" do
        Post.blueprint { }
        Comment.blueprint { }
        comment = nil
        post = Post.make_unsaved { comment = Comment.make }
        post.should be_new_record
        comment.should_not be_new_record
      end
    end
  
  end
end
