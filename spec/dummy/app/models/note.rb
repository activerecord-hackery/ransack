class Note < ApplicationRecord
  belongs_to :notable, polymorphic: true
end