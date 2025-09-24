class Person < ApplicationRecord
  default_scope { order(id: :desc) }
  belongs_to :parent, class_name: 'Person', foreign_key: :parent_id, optional: true
  has_many   :children, class_name: 'Person', foreign_key: :parent_id
  has_many   :articles
  has_many   :story_articles

  has_many :published_articles, ->{ where(published: true) },
      class_name: "Article"
  has_many   :comments
  has_many   :authored_article_comments, through: :articles,
             source: :comments, foreign_key: :person_id
  has_many   :notes, as: :notable

  scope :restricted,  lambda { where("restricted = 1") }
  scope :active,      lambda { where("active = 1") }
  scope :over_age,    lambda { |y| where(["age > ?", y]) }
  scope :of_age,      lambda { |of_age|
    of_age ? where("age >= ?", 18) : where("age < ?", 18)
  }

  scope :sort_by_reverse_name_asc, lambda { order(Arel.sql("REVERSE(name) ASC")) }
  scope :sort_by_reverse_name_desc, lambda { order("REVERSE(name) DESC") }

  enum :temperament, { sanguine: 1, choleric: 2, melancholic: 3, phlegmatic: 4 }

  alias_attribute :full_name, :name

  ransack_alias :term, :name_or_email
  ransack_alias :daddy, :parent_name

  ransacker :reversed_name, formatter: proc { |v| v.reverse } do |parent|
    parent.table[:name]
  end

  ransacker :array_people_ids,
    formatter: proc { |v| Person.first(2).map(&:id) } do |parent|
    parent.table[:id]
  end

  ransacker :array_where_people_ids,
    formatter: proc { |v| Person.where(id: v).map(&:id) } do |parent|
    parent.table[:id]
  end

  ransacker :array_people_names,
    formatter: proc { |v| Person.first(2).map { |p| p.id.to_s } } do |parent|
    parent.table[:name]
  end

  ransacker :array_where_people_names,
    formatter: proc { |v| Person.where(id: v).map { |p| p.id.to_s } } do |parent|
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

  ransacker :name_case_insensitive, type: :string do
    arel_table[:name].lower
  end

  ransacker :with_arguments, args: [:parent, :ransacker_args] do |parent, args|
    min, max = args
    query = <<-SQL
      (SELECT MAX(articles.title)
         FROM articles
        WHERE articles.person_id = people.id
          AND LENGTH(articles.body) BETWEEN #{min} AND #{max}
        GROUP BY articles.person_id
      )
    SQL
    .squish
    Arel.sql(query)
  end

  def self.ransackable_attributes(auth_object = nil)
    if auth_object == :admin
      authorizable_ransackable_attributes - ['only_sort']
    else
      authorizable_ransackable_attributes - ['only_sort', 'only_admin']
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