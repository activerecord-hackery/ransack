require File.dirname(__FILE__) + '/spec_helper'
require 'machinist/sequel'

# We have to define this here because Sequel needs a DB connection 
# setup before you can define models
DB = Sequel.sqlite(:logger => Logger.new(File.dirname(__FILE__) + "/log/test.log"))

DB.create_table :people do
  primary_key :id
  String :name
  String :type
  String :password
  Boolean :admin, :default => false
end

DB.create_table :posts do
  primary_key :id
  String :title
  String :body
  Boolean :published, :default => true
end

DB.create_table :comments do
  primary_key :id
  Integer :post_id
  Integer :author_id
  String :body
end

module MachinistSequelSpecs
  
  class Person < Sequel::Model
    set_restricted_columns :password
  end

  class Post < Sequel::Model
    one_to_many :comments, :class => "MachinistSequelSpecs::Comment"
  end

  class Comment < Sequel::Model
    many_to_one :post, :class => "MachinistSequelSpecs::Post"
    many_to_one :author, :class => "MachinistSequelSpecs::Person"
  end

  describe Machinist, "Sequel adapter" do  

    before(:each) do
      Person.clear_blueprints!
      Post.clear_blueprints!
      Comment.clear_blueprints!
    end

    describe "make method" do
      it "should save the constructed object" do
        Person.blueprint { }
        person = Person.make
        person.should_not be_new
      end
  
      it "should create and object through a many_to_one association" do
        Post.blueprint { }
        Comment.blueprint { post }
        Comment.make.post.class.should == Post
      end
  
      it "should create an object through many_to_one association with a class_name attribute" do
        Person.blueprint { }
        Comment.blueprint { author }
        Comment.make.author.class.should == Person
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
      
#       it "should allow setting the type attribute in a blueprint" do
#         Person.blueprint { type "Person" }
#         Person.make.type.should == "Person"
#       end
    end

    describe "plan method" do
      it "should not save the constructed object" do
        lambda {
          Person.blueprint { }
          person = Person.plan
        }.should_not change(Person,:count)
      end

      it "should return a regular attribute in the hash" do
        Post.blueprint { title "Test" }
        post = Post.plan
        post[:title].should == "Test"
      end

      it "should create an object through a many_to_one association, and return its id" do
        Post.blueprint { }
        Comment.blueprint { post }
        lambda {
          comment = Comment.plan
          comment[:post].should be_nil
          comment[:post_id].should_not be_nil
        }.should change(Post, :count).by(1)
      end
    end

    # Note that building up an unsaved object graph using just the
    # association methods is not possible in Sequel, so 
    # make_unsaved will break in amusing ways unless you manually 
    # override the setters.
    #
    # From sequel-talk "Sequel does not have such an API and will not be adding one"
    # Feb 17
    describe "make_unsaved method" do
      it "should not save the constructed object" do
        Person.blueprint { }
        person = Person.make_unsaved
        person.should be_new
      end
  
      it "should save objects made within a passed-in block" do
        Post.blueprint { }
        Comment.blueprint { }
        comment = nil
        post = Post.make_unsaved { comment = Comment.make }
        post.should be_new
        comment.should_not be_new
      end
    end
  end
end
