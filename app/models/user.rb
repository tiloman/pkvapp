class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  after_create :create_person
  has_many :people, dependent: :destroy
  has_one :todoist_integration

  def create_person
    Person.create(name: first_name, color: 'red', ratio: '50/50')
  end

  def full_name
    if first_name.present? && last_name.present?
      first_name + ' ' + last_name
    else
      email
    end
  end

  def operations_view
    prefered_operations_view || 'tile'
  end

  def remind_days_before
    5
  end
end
