class Article < ApplicationRecord
  belongs_to :person
  has_many :comments
  has_and_belongs_to_many :tags
  has_many :notes, as: :notable

  alias_attribute :content, :body

  default_scope { where("'default_scope' = 'default_scope'") }
  scope :latest_comment_cont, lambda { |msg|
    join = <<-SQL
      (LEFT OUTER JOIN (
          SELECT
            comments.*,
            row_number() OVER (PARTITION BY comments.article_id ORDER BY comments.id DESC) AS rownum
          FROM comments
        ) AS latest_comment
        ON latest_comment.article_id = article.id
        AND latest_comment.rownum = 1
      )
    SQL
    .squish

    joins(join).where("latest_comment.body ILIKE ?", "%#{msg}%")
  }

  ransacker :title_type, formatter: lambda { |tuples|
    title, type = JSON.parse(tuples)
    Arel::Nodes::Grouping.new(
      [
        Arel::Nodes.build_quoted(title),
        Arel::Nodes.build_quoted(type)
      ]
    )
  } do |_parent|
    articles = Article.arel_table
    Arel::Nodes::Grouping.new(
      %i[title type].map do |field|
        articles[field]
      end
    )
  end

  ransacker :title_type_sym, formatter: lambda { |tuples|
    title, type = JSON.parse(tuples)
    Arel::Nodes::Grouping.new(
      [
        Arel::Nodes.build_quoted(title),
        Arel::Nodes.build_quoted(type)
      ]
    )
  } do |_parent|
    articles = Article.arel_table
    Arel::Nodes::Grouping.new(
      [:title, :type].map do |field|
        articles[field]
      end
    )
  end

  ransacker :id_plus_one do |parent|
    Arel::Nodes::InfixOperation.new('+', parent.table[:id], Arel::Nodes.build_quoted(1))
  end

  ransacker :legacy_id do |parent|
    parent.table[:id]
  end
end