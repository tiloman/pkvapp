class TodoistIntegration < ApplicationRecord
  validates :token, presence: true
end
