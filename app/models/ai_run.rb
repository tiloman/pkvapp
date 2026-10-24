class AiRun < ApplicationRecord
  KINDS = %w[extract_bill].freeze
  STATUSES = %w[processing proposed accepted rejected failed reverted].freeze
  MAX_DOCUMENT_SIZE = 10.megabytes
  STALE_AFTER = 10.minutes

  belongs_to :user
  belongs_to :operation, optional: true
  has_one_attached :document

  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: STATUSES }
  validate :document_present_and_supported

  scope :awaiting_review, -> { where(status: 'proposed') }
  scope :accepted, -> { where(status: 'accepted') }

  STATUSES.each do |name|
    define_method(:"#{name}?") { status == name }
  end

  # A run that nobody picked up (e.g. no worker running) must not wait forever.
  def stale?
    processing? && created_at < STALE_AFTER.ago
  end

  def decided?
    accepted? || rejected? || reverted?
  end

  # Moves to a new status; terminal decisions get a timestamp.
  def transition_to!(new_status, **attributes)
    attributes[:decided_at] = Time.current if %w[accepted rejected reverted].include?(new_status)
    update!(attributes.merge(status: new_status))
  end

  def field_value(name)
    output.dig(name.to_s, 'value')
  end

  def field_confidence(name)
    output.dig(name.to_s, 'confidence')
  end

  def field_evidence(name)
    output.dig(name.to_s, 'evidence')
  end

  private

  def document_present_and_supported
    unless document.attached?
      errors.add(:document, :blank)
      return
    end

    unless document.content_type == 'application/pdf' || document.content_type.to_s.start_with?('image/')
      errors.add(:document, 'muss ein PDF oder Bild sein')
    end
    errors.add(:document, 'ist größer als 10 MB') if document.byte_size > MAX_DOCUMENT_SIZE
  end
end
