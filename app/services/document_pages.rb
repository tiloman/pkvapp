require 'open3'
require 'tmpdir'

# Turns an uploaded document into page images for models that cannot read PDFs natively.
class DocumentPages
  Page = Struct.new(:content_type, :data)

  MAX_PAGES = 4
  DPI = 150

  def self.call(document)
    return [Page.new(document.content_type, document.download)] unless document.content_type == 'application/pdf'

    render_pdf(document.download)
  end

  def self.render_pdf(data)
    Dir.mktmpdir('pdf-pages') do |dir|
      input = File.join(dir, 'input.pdf')
      File.binwrite(input, data)

      _out, err, status = Open3.capture3('pdftoppm', '-png', '-r', DPI.to_s, '-l', MAX_PAGES.to_s,
                                         input, File.join(dir, 'page'))
      files = Dir.glob(File.join(dir, 'page*.png')).sort_by { |f| f[/(\d+)\.png\z/, 1].to_i }
      unless status.success? && files.any?
        Rails.logger.warn("pdftoppm failed: #{err.to_s.truncate(300)}")
        raise AiClient::UnreadableDocumentError, 'Das PDF konnte nicht in Bilder umgewandelt werden.'
      end

      files.map { |file| Page.new('image/png', File.binread(file)) }
    end
  rescue Errno::ENOENT
    raise AiClient::ProviderError, 'pdftoppm (poppler-utils) ist auf dem Server nicht installiert.'
  end
  private_class_method :render_pdf
end
