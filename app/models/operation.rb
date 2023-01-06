class Operation < ApplicationRecord
  include AASM

  aasm do
    state :editing, initial: true
    state :closed, :open, :waiting

    event :close do
      transitions from: %i[editing open waiting], to: :closed
    end

    event :open do
      transitions from: %i[open closed waiting], to: :editing
    end

    event :wait do
      transitions from: %i[editing open closed], to: :waiting
    end
  end

  STATE_ORDER = %w[editing open waiting closed]

  belongs_to :person
  delegate :user, to: :person
  has_one_attached :bill
  has_one_attached :insurance_notice
  has_rich_text :content

  after_update :update_status
  after_create :reminder_job
  after_update :update_job
  before_update :insurance_submitted?
  validate :assistance_submitted?
  validates :title, presence: true, length: { minimum: 2, maximum: 100 }

  scope :search_query, ->(query) {
   where("LOWER(title) LIKE ?", "%#{query}%")
  }

  scope :sorted_by, ->(sort_option) {
    direction = /desc$/.match?(sort_option) ? "desc" : "asc"
    case sort_option.to_s
    when /^title/
      order("LOWER(operations.title) #{direction}")
    when /^created_at/
      order("operations.created_at #{direction}")
    when /^value/
      order("operations.value #{direction}")
    when /^paid/
      order("operations.paid #{direction}")
    when /^insurance_submitted/
      order("operations.insurance_submitted #{direction}")
    when /^insurance_paid/
      order("operations.insurance_paid #{direction}")
    when /^assistance_submitted/
      order("operations.assistance_submitted #{direction}")
    when /^assistance_paid/
      order("operations.assistance_paid #{direction}")
    when /^person/
      joins(:person).order("people.name #{direction}")
    when /^aasm_state/
      order("operations.aasm_state #{direction}")
    else
      raise(ArgumentError, "Invalid sort option: #{sort_option.inspect}")
    end
  }
  scope :by_person, ->(person_id) {where(person_id: person_id)}
  scope :by_state, ->(state) {where(aasm_state: state)}
  scope :overdue, -> { where('bill_deadline <= ? AND paid IS ?', Time.now, false) }
  scope :unpaid_operations, -> { where(paid: false) }
  scope :paid_operations, -> { where(paid: true) }

  filterrific(
   default_filter_params: { sorted_by: 'created_at_desc' },
   available_filters: [
     :sorted_by,
     :search_query,
     :by_person,
     :by_state
   ]
 )

  def self.options_for_person_select(current_user)
    current_user.people.pluck(:name, :id)
  end

  def self.options_for_state_select(scope)
    scope.all.map { |operation| [I18n.t("#{operation.aasm_state}", scope: 'operations.aasm_state'), operation.aasm_state]}.uniq
  end

  def has_attachments?
    return true if bill.attached? || insurance_notice.attached?
  end

  def insurance_submitted?
    if insurance_submitted && insurance_paid == true || insurance_paid == false
      true
    else
      errors[:base] << 'Versicherung noch nicht eingereicht'
      throw :abort
    end
  end

  def assistance_submitted?
    if assistance_submitted && assistance_paid == true || assistance_paid == false
      true
    else
      errors[:base] << 'Beihilfe noch nicht eingereicht'
      throw :abort
    end
  end

  def update_status
    if assistance_paid && insurance_paid && paid
      close! if editing? || waiting?
    elsif assistance_submitted && insurance_submitted && paid
      wait! if editing? || closed?
    elsif closed? || waiting?
      open!
    end
  end

  def reminder_job
    OperationsMailer.delay(run_at: remind_at).deadline_reminder(id)
  end

  def update_job
    return unless find_reminder_job.any?

    find_reminder_job.first.update_attribute(:run_at, remind_at)
  end

  def remind_at
    return unless bill_deadline

    bill_deadline - 7.days
  end

  def find_reminder_job
    Delayed::Job.where(
      "handler like (?) AND handler like (?)",
      "%method_name: :deadline_reminder%", "%args:\n- #{self.id}%"
    )
  end

  def start_time
    bill_deadline
  end
end
