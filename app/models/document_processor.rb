# frozen_string_literal: true

class DocumentProcessor
  MAX_PAGES = 50
  IMAGE_DPI = 150

  class ProcessingError < StandardError; end

  # Extracts text from a PDF file using pdftotext
  # Returns UTF-8 encoded text string
  def extract_text(pdf_path)
    stdout, stderr, status = Open3.capture3("pdftotext", "-layout", pdf_path.to_s, "-")
    raise ProcessingError, "pdftotext failed: #{stderr}" unless status.success?

    stdout.encode("UTF-8", invalid: :replace, undef: :replace)
  end

  # Converts PDF pages to PNG images using pdftoppm
  # Returns array of hashes with :io, :filename, :content_type
  def convert_to_images(pdf_path)
    Dir.mktmpdir("document_processor") do |tmpdir|
      stdout, stderr, status = Open3.capture3(
        "pdftoppm", "-png", "-r", IMAGE_DPI.to_s,
        "-l", MAX_PAGES.to_s,
        pdf_path.to_s, File.join(tmpdir, "page")
      )
      raise ProcessingError, "pdftoppm failed: #{stderr}" unless status.success?

      Dir.glob(File.join(tmpdir, "page-*.png")).sort.map do |image_path|
        page_num = File.basename(image_path, ".png").match(/-(\d+)$/)[1].to_i
        content = File.binread(image_path)
        {
          io: StringIO.new(content),
          filename: "page-#{page_num}.png",
          content_type: "image/png",
          page_number: page_num,
          byte_size: content.bytesize
        }
      end
    end
  end

  # Converts PPTX/PPT to PDF using LibreOffice
  # Returns path to the generated PDF file
  def convert_presentation_to_pdf(pptx_path)
    outdir = File.dirname(pptx_path)
    stdout, stderr, status = Open3.capture3(
      "libreoffice", "--headless", "--convert-to", "pdf",
      "--outdir", outdir,
      pptx_path.to_s
    )
    raise ProcessingError, "libreoffice conversion failed: #{stderr}" unless status.success?

    pdf_path = File.join(outdir, "#{File.basename(pptx_path, File.extname(pptx_path))}.pdf")
    raise ProcessingError, "PDF output not found at #{pdf_path}" unless File.exist?(pdf_path)

    pdf_path
  end
end
