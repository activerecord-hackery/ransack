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
    default_scope { order(id: :desc) }
  end
  belongs_to :parent, :class_name => 'Person', :foreign_key => :parent_id
  has_many   :children, :class_name => 'Person', :foreign_key => :parent_id
  has_many   :articles
  has_many   :comments
  has_many   :authored_article_comments, :through => :articles,
             :source => :comments, :foreign_key => :person_id
  has_many   :notes, :as => :notable

  scope :restricted,  lambda { where("restricted = 1") }
  scope :active,      lambda { where("active = 1") }
  scope :over_age,    lambda { |y| where(["age > ?", y]) }
  scope :of_age,      lambda { |of_age|
    of_age ? where("age >= ?", 18) : where("age < ?", 18)
  }

  ransacker :reversed_name, :formatter => proc { |v| v.reverse } do |parent|
    parent.table[:name]
  end

  ransacker :array_users,
    formatter: proc { |v| Person.first(2).map(&:id) } do |parent|
    parent.table[:id]
  end

  ransacker :array_names,
    formatter: proc { |v| Person.first(2).map { |p| p.id.to_s } } do |parent|
    parent.table[:name]
  end

  ransacker :doubled_name do |parent|
    Arel::Nodes::InfixOperation.new(
      '||', parent.table[:name], parent.table[:name]
      )
  end

  ransacker :sql_literal_id do
    Arel.sql('people.id')
  end

  ransacker :with_passed_arguments, args: [:parent, :ransacker_args] do |parent, args|
    min_body, max_body = args
    sql = <<-SQL
      (SELECT MAX(articles.title)
         FROM articles
        WHERE articles.person_id = people.id
          AND CHAR_LENGTH(articles.body) BETWEEN #{min_body} AND #{max_body}
        GROUP BY articles.person_id
      )
    SQL
    Arel.sql(sql.squish)
  end

  ransacker :dynamic_hstore, args: [:parent, :ransacker_args] do |parent, args|
    column, field = args
    Arel::Nodes::InfixOperation.new("->", Person.arel_table[column], Arel::Nodes.build_quoted(field))
  end

  def self.ransackable_attributes(auth_object = nil)
    if auth_object == :admin
      column_names + _ransackers.keys - ['only_sort']
    else
      column_names + _ransackers.keys - ['only_sort', 'only_admin']
    end
  end

  def self.ransortable_attributes(auth_object = nil)
    if auth_object == :admin
      column_names + _ransackers.keys - ['only_search']
    else
      column_names + _ransackers.keys - ['only_search', 'only_admin']
    end
  end

end

class Article < ActiveRecord::Base
  belongs_to :person
  has_many :comments
  has_and_belongs_to_many :tags
  has_many :notes, :as => :notable

  if ActiveRecord::VERSION::STRING >= '3.1'
    default_scope { where("'default_scope' = 'default_scope'") }
  else # Rails 3.0 does not accept a block
    default_scope where("'default_scope' = 'default_scope'")
  end
end

module Namespace
  class Article < ::Article

  end
end

module Namespace
  class Article < ::Article

  end
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
        t.string   :only_search
        t.string   :only_sort
        t.string   :only_admin
        t.string   :new_start
        t.string   :stop_end
        t.integer  :salary
        t.date     :life_start
        t.boolean  :awesome, default: false
        t.boolean  :terms_and_conditions, default: false
        t.boolean  :true_or_false, default: true
        t.timestamps null: false
      end

      create_table :articles, :force => true do |t|
        t.integer :person_id
        t.string  :title
        t.text    :subject_header
        t.text    :body
      end

      create_table :comments, :force => true do |t|
        t.integer :article_id
        t.integer :person_id
        t.text :body
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
        t.string :notable_type
        t.string :note
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
          Comment.make(:article => article, :person => person)
        end
      end
    end

    Comment.make(
      :body => 'First post!',
      :article => Article.make(:title => 'Hello, world!')
      )
  end
end
