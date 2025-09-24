require File.dirname(__FILE__) + '/spec_helper'
require 'machinist/data_mapper'
require 'dm-validations'

module MachinistDataMapperSpecs
  
  class Person
    include DataMapper::Resource
    property :id,       Serial
    property :name,     String,  :length => (0..10)
    property :type,     Discriminator
    property :password, String
    property :admin,    Boolean, :default => false
  end

  class Admin < Person
  end

  class Post
    include DataMapper::Resource
    property :id,        Serial
    property :title,     String
    property :body,      Text
    property :published, Boolean, :default => true
    has n, :comments
  end

  class Comment
    include DataMapper::Resource
    property :id,        Serial
    property :post_id,   Integer
    property :author_id, Integer
    belongs_to :post
    belongs_to :author, :model => "Person", :child_key => [:author_id]
  end

  describe Machinist, "DataMapper adapter" do  
    before(:suite) do
      DataMapper::Logger.new(File.dirname(__FILE__) + "/log/test.log", :debug)
      DataMapper.setup(:default, "sqlite3::memory:")
      DataMapper.auto_migrate!
    end

    before(:each) do
      [Person, Admin, Post, Comment].each(&:clear_blueprints!)
    end

    describe "make method" do
      it "should support inheritance" do
        Person.blueprint {}
        Admin.blueprint {}

        admin = Admin.make
        admin.should_not be_new
        admin.type.should_not be_nil
      end

      it "should save the constructed object" do
        Person.blueprint { }
        person = Person.make
        person.should_not be_new
      end

      it "should create an object through a belongs_to association" do
        Post.blueprint { }
        Comment.blueprint { post }
        Comment.make.post.class.should == Post
      end


      it "should create an object through a belongs_to association with a class_name attribute" do
        Person.blueprint { }
        Comment.blueprint { author }
        Comment.make.author.class.should == Person
      end

      it "should raise an exception if the object can't be saved" do
        Person.blueprint { }
        lambda { Person.make(:name => "More than ten characters") }.should raise_error(RuntimeError)
      end
    end

    describe "plan method" do
      it "should not save the constructed object" do
        person_count = Person.all.length
        Person.blueprint { }
        person = Person.plan
        Person.all.length.should == person_count
      end
  
      it "should return a regular attribute in the hash" do
        Post.blueprint { title "Test" }
        post = Post.plan
        post[:title].should == "Test"
      end

      it "should create an object through a belongs_to association, and return its id" do
        Post.blueprint { }
        Comment.blueprint { post }
        post_count = Post.all.length
        comment = Comment.plan
        Post.all.length.should == post_count + 1
        comment[:post].should be_nil
        comment[:post_id].should_not be_nil
      end
    end

    describe "make_unsaved method" do
      it "should not save the constructed object" do
        Person.blueprint { }
        person = Person.make_unsaved
        person.should be_new
      end
  
      it "should not save associated objects" do
        Post.blueprint { }
        Comment.blueprint { post }
        comment = Comment.make_unsaved
        comment.post.should be_new
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

