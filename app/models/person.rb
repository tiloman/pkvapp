class Person < ApplicationRecord
  has_many :operations, dependent: :destroy
  belongs_to :user

  default_scope { order(name: :asc) }
end
