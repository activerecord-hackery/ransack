class Recommendation < ApplicationRecord
  belongs_to :person
  belongs_to :target_person, class_name: 'Person'
  belongs_to :article
end