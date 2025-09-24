Machinist
=========

*Fixtures aren't fun. Machinist is.*
  
Machinist makes it easy to create test data within your tests. It generates data for the fields you don't care about, and constructs any necessary associated objects, leaving you to only specify the fields you *do* care about in your tests. For example:

    describe Comment do
      before do
        # This will make a Comment, a Post, and a User (the author of
        # the Post), and generate values for all their attributes:
        @comment = Comment.make(:spam => true)
      end
    
      it "should not include comments marked as spam in the without_spam named scope" do
        Comment.without_spam.should_not include(@comment)
      end
    end

You tell Machinist how to do this with blueprints:

    require 'machinist/active_record'
    require 'sham'
    require 'faker'
  
    Sham.name  { Faker::Name.name }
    Sham.email { Faker::Internet.email }
    Sham.title { Faker::Lorem.sentence }
    Sham.body  { Faker::Lorem.paragraph }
  
    User.blueprint do
      name
      email
    end
  
    Post.blueprint do
      title
      author
      body
    end
  
    Comment.blueprint do
      post
      author_name  { Sham.name }
      author_email { Sham.email }
      body
    end
    

Download & Install
==================

### Installing as a Rails plugin

    ./script/plugin install git://github.com/notahat/machinist.git
      
### Installing as a Gem

    sudo gem install machinist --source http://gemcutter.org

### Setting up your project

Create a `blueprints.rb` file to hold your blueprints in your test (or spec) directory. It should start with:

    require 'machinist/active_record'
    require 'sham'
    
Substitute `data_mapper` or `sequel` for `active_record` if that's your weapon of choice.
    
Require `blueprints.rb` in your `test_helper.rb` (or `spec_helper.rb`):

    require File.expand_path(File.dirname(__FILE__) + "/blueprints")

Set Sham to reset before each test. In the `class Test::Unit::TestCase` block in your `test_helper.rb`, add:
    
    setup { Sham.reset }
    
or, if you're on RSpec, in the `Spec::Runner.configure` block in your `spec_helper.rb`, add:

    config.before(:all)    { Sham.reset(:before_all)  }
    config.before(:each)   { Sham.reset(:before_each) }

    
Documentation
=============

Sham - Generating Attribute Values
----------------------------------

Sham lets you generate random but repeatable unique attributes values.

For example, you could define a way to generate random names as:

    Sham.name { (1..10).map { ('a'..'z').to_a.rand }.join }

Then, to generate a name, call:

    Sham.name

So why not just define a helper method to do this? Sham ensures two things for you:

1. You get the same sequence of values each time your test is run
2. You don't get any duplicate values
    
Sham works very well with the excellent [Faker gem](http://faker.rubyforge.org/) by Benjamin Curtis. Using this, a much nicer way to generate names is:
    
    Sham.name { Faker::Name.name }
    
Sham also supports generating numbered sequences if you prefer.

    Sham.name {|index| "Name #{index}" }
    
If you want to allow duplicate values for a sham, you can pass the `:unique` option:

    Sham.coin_toss(:unique => false) { rand(2) == 0 ? 'heads' : 'tails' }
    
You can create a bunch of sham definitions in one hit like this:

    Sham.define do
      title { Faker::Lorem.words(5).join(' ') }
      name  { Faker::Name.name }
      body  { Faker::Lorem.paragraphs(3).join("\n\n") }
    end


Blueprints - Generating Objects
-------------------------------

A blueprint describes how to generate an object. The idea is that you let the blueprint take care of making up values for attributes that you don't care about in your test, leaving you to focus on the just the things that you're testing.

A simple blueprint might look like this:

    Post.blueprint do
      title  { Sham.title }
      author { Sham.name }
      body   { Sham.body }
    end

You can then construct a Post from this blueprint with:
    
    Post.make
    
When you call `make`, Machinist calls `Post.new`, then runs through the attributes in your blueprint, calling the block for each attribute to generate a value. The Post is then saved and reloaded. An exception is thrown if Post can't be saved.

You can override values defined in the blueprint by passing a hash to make:

    Post.make(:title => "A Specific Title")
    
If you don't supply a block for an attribute in the blueprint, Machinist will look for a Sham definition with the same name as the attribute, so you can shorten the above blueprint to:

    Post.blueprint do
      title
      author { Sham.name }
      body
    end
    
If you want to generate an object without saving it to the database, replace `make` with `make_unsaved`. (`make_unsaved` also ensures that any associated objects that need to be generated are not saved - although not if you are using Sequel. See the section on associations below.)

You can refer to already assigned attributes when constructing a new attribute:

    Post.blueprint do
      title
      author { Sham.name }
      body   { "Post by #{author}" }
    end
        

### Named Blueprints

Named blueprints let you define variations on an object. For example, suppose some of your Users are administrators:

    User.blueprint do
      name
      email
    end

    User.blueprint(:admin) do
      name  { Sham.name + " (admin)" }
      admin { true }
    end

Calling:

    User.make(:admin)

will use the `:admin` blueprint.

Named blueprints call the default blueprint to set any attributes not specifically provided, so in this example the `email` attribute will still be generated even for an admin user.


### Belongs\_to Associations

If you're generating an object that belongs to another object, you can generate the associated object like this:
    
    Comment.blueprint do
      post { Post.make }
    end
    
Calling `Comment.make` will construct a Comment and its associated Post, and save both.

If you want to override the value for post when constructing the comment, you can do this:

    post = Post.make(:title => "A particular title)
    comment = Comment.make(:post => post)
    
Machinist will not call the blueprint block for the post attribute, so this won't generate two posts.
    
Machinist is smart enough to look at the association and work out what sort of object it needs to create, so you can shorten the above blueprint to:
    
    Comment.blueprint do
      post
    end

    
### Other Associations

For has\_many and has\_and\_belongs\_to\_many associations, ActiveRecord insists that the object be saved before any associated objects can be saved. That means you can't generate the associated objects from within the blueprint.

The simplest solution is to write a test helper:

    def make_post_with_comments(attributes = {})
      post = Post.make(attributes)
      3.times { post.comments.make }
      post
    end

Note here that you can call `make` on a has\_many association. (This isn't yet supported for DataMapper.)

Make can take a block, into which it passes the constructed object, so the above can be written as:

    def make_post_with_comments
      Post.make(attributes) do |post|
        3.times { post.comments.make }
      end
    end


### Using Blueprints in Rails Controller Tests

The `plan` method behaves like `make`, except it returns a hash of attributes, and doesn't save the object. This is useful for passing in to controller tests:

    test "should create post" do
      assert_difference('Post.count') do
        post :create, :post => Post.plan
      end
      assert_redirected_to post_path(assigns(:post))
    end
    
`plan` will save any associated objects. In this example, it will create an Author, and it knows that the controller expects an `author_id` attribute, rather than an `author` attribute, and makes this translation for you.
    
You can also call plan on has\_many associations, making it easy to test nested controllers:

    test "should create comment" do
      post = Post.make
      assert_difference('Comment.count') do
        post :create, :post_id => post.id, :comment => post.comments.plan
      end
      assert_redirected_to post_comment_path(post, assigns(:comment))
    end
    
(Calling plan on associations is not yet supported in DataMapper.)


### Blueprints on Plain Old Ruby Objects

Machinist also works with plain old Ruby objects. Let's say you have a class like:

    class Post
      attr_accessor :title
      attr_accessor :body
    end
    
You can then do the following in your `blueprints.rb`:

    require 'machinist/object'
    
    Post.blueprint do
      title "A title!"
      body  "A body!"
    end

Community
=========

You can always find the [latest version on GitHub](http://github.com/notahat/machinist).

If you have questions, check out the [Google Group](http://groups.google.com/group/machinist-users).

File bug reports and feature requests in the [issue tracker](http://github.com/notahat/machinist/issues).

Contributors
------------

Machinist is maintained by Pete Yandell ([pete@notahat.com](mailto:pete@notahat.com), [@notahat](http://twitter.com/notahat))

Other contributors include:

[Marcos Arias](http://github.com/yizzreel),
[Jack Dempsey](http://github.com/jackdempsey),
[Clinton Forbes](http://github.com/clinton),
[Perryn Fowler](http://github.com/perryn),
[Niels Ganser](http://github.com/Nielsomat),
[Jeremy Grant](http://github.com/jeremygrant),
[Jon Guymon](http://github.com/gnarg),
[James Healy](http://github.com/yob),
[Evan David Light](http://github.com/elight),
[Chris Lloyd](http://github.com/chrislloyd),
[Adam Meehan](http://github.com/adzap),
[Kyle Neath](http://github.com/kneath),
[Lawrence Pit](http://github.com/lawrencepit),
[T.J. Sheehy](http://github.com/tjsheehy),
[Roland Swingler](http://github.com/knaveofdiamonds),
[Gareth Townsend](http://github.com/quamen),
[Matt Wastrodowski](http://github.com/towski),
[Ian White](http://github.com/ianwhite)

Thanks to Thoughtbot's [Factory Girl](http://github.com/thoughtbot/factory_girl/tree/master). Machinist was written because I loved the idea behind Factory Girl, but I thought the philosophy wasn't quite right, and I hated the syntax.
