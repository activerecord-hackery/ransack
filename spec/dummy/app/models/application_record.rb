# This is just a test app with no sensitive data, so we explicitly allowlist all
# attributes and associations for search. In general, end users should
# explicitly authorize each model, but this shows a way to configure the
# unrestricted default behavior of versions prior to Ransack 4.
#
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.ransackable_attributes(auth_object = nil)
    authorizable_ransackable_attributes
  end

  def self.ransackable_associations(auth_object = nil)
    authorizable_ransackable_associations
  end
end