require 'rails_helper'

RSpec.describe AiRun, type: :model do
  let(:user) { FactoryBot.create(:user) }

  def build_run(content_type: 'application/pdf', data: 'pdf', **attrs)
    run = described_class.new({ user: user, kind: 'extract_bill' }.merge(attrs))
    run.document.attach(io: StringIO.new(data), filename: 'rechnung', content_type: content_type)
    run
  end

  it 'is valid with a pdf document' do
    expect(build_run).to be_valid
  end

  it 'accepts images' do
    expect(build_run(content_type: 'image/jpeg')).to be_valid
  end

  it 'requires a document' do
    expect(described_class.new(user: user, kind: 'extract_bill')).not_to be_valid
  end

  it 'rejects unsupported document types' do
    expect(build_run(content_type: 'text/plain')).not_to be_valid
  end

  it 'rejects oversized documents' do
    run = build_run
    allow(run.document).to receive(:byte_size).and_return(11.megabytes)
    expect(run).not_to be_valid
  end

  it 'rejects unknown kinds and statuses' do
    expect(build_run(kind: 'foo')).not_to be_valid
    expect(build_run(status: 'foo')).not_to be_valid
  end

  it 'starts as processing' do
    expect(build_run).to be_processing
  end

  describe '#transition_to!' do
    it 'stamps decisions' do
      run = build_run.tap(&:save!)
      run.transition_to!('proposed')
      expect(run.decided_at).to be_nil
      run.transition_to!('accepted')
      expect(run).to be_accepted
      expect(run.decided_at).to be_present
    end
  end

  describe '#stale?' do
    it 'is true only for processing runs older than ten minutes' do
      run = build_run.tap(&:save!)
      expect(run).not_to be_stale
      run.update_column(:created_at, 11.minutes.ago)
      expect(run).to be_stale
      run.transition_to!('proposed')
      expect(run).not_to be_stale
    end
  end

  describe 'field readers' do
    it 'reads value, confidence and evidence from output' do
      run = build_run(output: { 'total_amount' => { 'value' => 42.5, 'confidence' => 0.9, 'evidence' => 'Summe 42,50 €' } })
      expect(run.field_value(:total_amount)).to eq(42.5)
      expect(run.field_confidence(:total_amount)).to eq(0.9)
      expect(run.field_evidence(:total_amount)).to eq('Summe 42,50 €')
      expect(run.field_value(:missing)).to be_nil
    end
  end
end
