class TodoistIntegration < ApplicationRecord
  validates :email, :password, presence: true
end
