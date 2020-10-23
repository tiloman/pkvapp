class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  after_create :create_person

  has_many :people, dependent: :destroy

  def create_person
	   Person.create(name: self.first_name, color: "red", ratio: "50/50")
  end

  def full_name
    if first_name.present? && last_name.present?
      return first_name + " " + last_name
    else
      return email
    end
  end
  
end
