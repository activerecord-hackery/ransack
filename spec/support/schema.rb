require 'active_record'

case ENV['DB']
when "mysql"
  ActiveRecord::Base.establish_connection(
    adapter:  'mysql2',
    database: 'ransack',
    encoding: 'utf8'
  )
when "postgres"
  ActiveRecord::Base.establish_connection(
    adapter: 'postgresql',
    database: 'ransack',
    username: 'postgres',
    min_messages: 'warning'
  )
else
  # Assume SQLite3
  ActiveRecord::Base.establish_connection(
    adapter: 'sqlite3',
    database: ':memory:'
  )
end

class Person < ActiveRecord::Base
  if ActiveRecord::VERSION::MAJOR == 3
    default_scope order('id DESC')
  else
    default_scope { order('id DESC') }
    # The new activerecord syntax "{ order(id: :desc) }" does not work
    # with Ruby 1.8.7 which we still need to support for Rails 3
  end
  belongs_to :parent, :class_name => 'Person', :foreign_key => :parent_id
  has_many   :children, :class_name => 'Person', :foreign_key => :parent_id
  has_many   :articles
  has_many   :comments
  has_many   :authored_article_comments, :through => :articles,
             :source => :comments, :foreign_key => :person_id
  has_many   :notes, :as => :notable

  ransacker :reversed_name, :formatter => proc {|v| v.reverse} do |parent|
    parent.table[:name]
  end

  ransacker :doubled_name do |parent|
    Arel::Nodes::InfixOperation.new('||', parent.table[:name], parent.table[:name])
  end
end

class Article < ActiveRecord::Base
  belongs_to              :person
  has_many                :comments
  has_and_belongs_to_many :tags
  has_many   :notes, :as => :notable
end

class Comment < ActiveRecord::Base
  belongs_to :article
  belongs_to :person
end

class Tag < ActiveRecord::Base
  has_and_belongs_to_many :articles
end

class Note < ActiveRecord::Base
  belongs_to :notable, :polymorphic => true
end

module Schema
  def self.create
    ActiveRecord::Migration.verbose = false

    ActiveRecord::Schema.define do
      create_table :people, :force => true do |t|
        t.integer  :parent_id
        t.string   :name
        t.string   :email
        t.integer  :salary
        t.boolean  :awesome, :default => false
        t.timestamps
      end

      create_table :articles, :force => true do |t|
        t.integer :person_id
        t.string  :title
        t.text    :body
      end

      create_table :comments, :force => true do |t|
        t.integer :article_id
        t.integer :person_id
        t.text    :body
      end

      create_table :tags, :force => true do |t|
        t.string :name
      end

      create_table :articles_tags, :force => true, :id => false do |t|
        t.integer :article_id
        t.integer :tag_id
      end

      create_table :notes, :force => true do |t|
        t.integer :notable_id
        t.string  :notable_type
        t.string  :note
      end

    end

    10.times do
      person = Person.make
      Note.make(:notable => person)
      3.times do
        article = Article.make(:person => person)
        3.times do
          article.tags = [Tag.make, Tag.make, Tag.make]
        end
        Note.make(:notable => article)
        10.times do
          Comment.make(:article => article)
        end
      end
      2.times do
        Comment.make(:person => person)
      end
    end

    Comment.make(:body => 'First post!', :article => Article.make(:title => 'Hello, world!'))

  end
end
