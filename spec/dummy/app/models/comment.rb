class Comment < ApplicationRecord
  belongs_to :article
  belongs_to :person

  alias_attribute :content, :body

  scope :active, lambda {
    where('active = 1')
  }

  scope :over_comments_count, lambda { |count|
    having("COUNT(id) > #{count}").group(:article_id)
  }
end