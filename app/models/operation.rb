class Operation < ApplicationRecord
  include AASM

  aasm do

  	state :editing, initial: true
    state :closed, :open, :waiting

    event :close do
      transitions from: [:editing, :open, :waiting], to: :closed
    end

    event :open do
      transitions from: [:open, :closed, :waiting], to: :editing
    end

    event :wait do
      transitions from: [:editing, :open, :closed], to: :waiting
    end

  end


  belongs_to :person


  has_one_attached :bill
  has_one_attached :insurance_notice

  has_rich_text :content

  default_scope { order(billing_date: :asc) }

  scope :closed_operations, -> { where(aasm_state: "closed") }
  scope :on_hold_operations, -> { where(aasm_state: "waiting") }
  scope :open_operations, -> { where(aasm_state: "editing") }

  after_update :update_status
  before_update :insurance_submitted?
  validate :assistance_submitted?
  validates :title, presence: true, length: { minimum: 2, maximum: 100}

  def has_attachments?
  	return true if bill.attached? || insurance_notice.attached?
  end


  def insurance_submitted?
      if insurance_submitted && insurance_paid == true || insurance_paid == false
        return true
      else
        errors[:base] << "Versicherung noch nicht eingereicht"
        throw :abort
      end
  end

  def assistance_submitted?
      if assistance_submitted && assistance_paid == true || assistance_paid == false
        return true
      else
        errors[:base] << "Beihilfe noch nicht eingereicht"
        throw :abort
      end
  end

  def update_status
  	if assistance_paid && insurance_paid
  		self.close! if editing? || waiting?
  	elsif assistance_submitted && insurance_submitted
      self.wait! if editing? || closed?
    else
  		self.open! if closed? || waiting?
  	end
  end
end
