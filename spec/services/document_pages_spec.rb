require 'rails_helper'

RSpec.describe DocumentPages do
  let(:ok) { instance_double(Process::Status, success?: true) }
  let(:failed) { instance_double(Process::Status, success?: false) }

  def document(content_type, data = 'bytes')
    Struct.new(:content_type, :download).new(content_type, data)
  end

  it 'passes images through unchanged' do
    pages = described_class.call(document('image/jpeg', 'jpg-bytes'))
    expect(pages.map(&:to_a)).to eq([['image/jpeg', 'jpg-bytes']])
  end

  it 'renders every pdf page as png, in page order' do
    allow(Open3).to receive(:capture3) do |*args|
      prefix = args.last
      %w[10 2 1].each { |n| File.binwrite("#{prefix}-#{n}.png", "page#{n}") }
      ['', '', ok]
    end

    pages = described_class.call(document('application/pdf', '%PDF'))
    expect(pages.map(&:data)).to eq(%w[page1 page2 page10])
    expect(pages.map(&:content_type).uniq).to eq(['image/png'])
    expect(Open3).to have_received(:capture3).with('pdftoppm', '-png', '-r', '150', '-l', '4', anything, anything)
  end

  it 'raises UnreadableDocumentError when pdftoppm fails' do
    allow(Open3).to receive(:capture3).and_return(['', 'Syntax Error', failed])
    expect { described_class.call(document('application/pdf')) }.to raise_error(AiClient::UnreadableDocumentError)
  end

  it 'raises UnreadableDocumentError when no page was produced' do
    allow(Open3).to receive(:capture3).and_return(['', '', ok])
    expect { described_class.call(document('application/pdf')) }.to raise_error(AiClient::UnreadableDocumentError)
  end

  it 'explains a missing pdftoppm binary' do
    allow(Open3).to receive(:capture3).and_raise(Errno::ENOENT)
    expect { described_class.call(document('application/pdf')) }
      .to raise_error(AiClient::ProviderError, /poppler-utils/)
  end
end
