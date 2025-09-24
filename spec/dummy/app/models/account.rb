class Account < ApplicationRecord
  belongs_to :agent_account, class_name: 'Account', optional: true
  belongs_to :trade_account, class_name: 'Account', optional: true
end