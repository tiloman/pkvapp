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

  STATE_ORDER = ['editing', 'open', 'waiting','closed']

  belongs_to :person


  has_one_attached :bill
  has_one_attached :insurance_notice

  has_rich_text :content

  default_scope { order(billing_date: :asc) }

  scope :overdue, -> { where("bill_deadline <= ? AND paid IS ?", Time.now, false) }
  scope :unpaid_operations, -> { where(paid: false) }
  scope :paid_operations, -> { where(paid: true) }
  scope :closed_operations, -> { where(aasm_state: "closed") }
  scope :on_hold_operations, -> { where(aasm_state: "waiting") }
  scope :open_operations, -> { where(aasm_state: "editing") }
  scope :order_by_status, -> {
  order(<<-SQL)
    CASE operations.aasm_state
    WHEN 'editing' THEN 'a'
    WHEN 'open' THEN 'b'
    WHEN 'waiting' THEN 'c'
    ELSE 'z'
    END ASC,
    id ASC
  SQL
}



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
  	if assistance_paid && insurance_paid && paid
  		self.close! if editing? || waiting?
  	elsif assistance_submitted && insurance_submitted && paid
      self.wait! if editing? || closed?
    else
  		self.open! if closed? || waiting?
  	end
  end

  def start_time
    #only for calendar
    self.bill_deadline ##Where 'start' is a attribute of type 'Date' accessible through MyModel's relationship
  end





end
