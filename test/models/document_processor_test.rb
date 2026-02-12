# frozen_string_literal: true

require "test_helper"
require "open3"

class DocumentProcessorTest < ActiveSupport::TestCase
  setup do
    @processor = DocumentProcessor.new
  end

  test "extract_text calls pdftotext and returns UTF-8 text" do
    expected_text = "Hello, IETF!\nPage 1 content"
    mock_status = Minitest::Mock.new
    mock_status.expect(:success?, true)

    Open3.stub(:capture3, [ expected_text.dup, "", mock_status ]) do
      result = @processor.extract_text("/tmp/test.pdf")

      assert_equal expected_text, result
      assert_equal Encoding::UTF_8, result.encoding
    end
  end

  test "extract_text raises ProcessingError on failure" do
    mock_status = Minitest::Mock.new
    mock_status.expect(:success?, false)

    Open3.stub(:capture3, [ "", "error occurred", mock_status ]) do
      error = assert_raises(DocumentProcessor::ProcessingError) do
        @processor.extract_text("/tmp/test.pdf")
      end
      assert_includes error.message, "pdftotext failed"
    end
  end

  test "convert_to_images calls pdftoppm and returns image data" do
    mock_status = Minitest::Mock.new
    mock_status.expect(:success?, true)

    Dir.mktmpdir("document_processor_test") do |tmpdir|
      # Create fake PNG files that pdftoppm would generate
      File.binwrite(File.join(tmpdir, "page-1.png"), "PNG_DATA_1")
      File.binwrite(File.join(tmpdir, "page-2.png"), "PNG_DATA_2")

      mktmpdir_stub = ->(_prefix, &block) { block.call(tmpdir) }
      Dir.stub(:mktmpdir, mktmpdir_stub) do
        Open3.stub(:capture3, [ "", "", mock_status ]) do
          result = @processor.convert_to_images("/tmp/test.pdf")

          assert_equal 2, result.size

          assert_equal 1, result[0][:page_number]
          assert_equal "page-1.png", result[0][:filename]
          assert_equal "image/png", result[0][:content_type]
          assert_equal "PNG_DATA_1".bytesize, result[0][:byte_size]

          assert_equal 2, result[1][:page_number]
          assert_equal "page-2.png", result[1][:filename]
        end
      end
    end
  end

  test "convert_to_images raises ProcessingError on failure" do
    mock_status = Minitest::Mock.new
    mock_status.expect(:success?, false)

    Dir.mktmpdir("document_processor_test") do |tmpdir|
      mktmpdir_stub = ->(_prefix, &block) { block.call(tmpdir) }
      Dir.stub(:mktmpdir, mktmpdir_stub) do
        Open3.stub(:capture3, [ "", "pdftoppm error", mock_status ]) do
          error = assert_raises(DocumentProcessor::ProcessingError) do
            @processor.convert_to_images("/tmp/test.pdf")
          end
          assert_includes error.message, "pdftoppm failed"
        end
      end
    end
  end

  test "convert_presentation_to_pdf calls libreoffice and returns pdf path" do
    mock_status = Minitest::Mock.new
    mock_status.expect(:success?, true)

    Dir.mktmpdir do |tmpdir|
      pptx_path = File.join(tmpdir, "slides.pptx")
      pdf_path = File.join(tmpdir, "slides.pdf")
      FileUtils.touch(pptx_path)
      FileUtils.touch(pdf_path)

      Open3.stub(:capture3, [ "", "", mock_status ]) do
        result = @processor.convert_presentation_to_pdf(pptx_path)
        assert_equal pdf_path, result
      end
    end
  end

  test "convert_presentation_to_pdf raises ProcessingError on failure" do
    mock_status = Minitest::Mock.new
    mock_status.expect(:success?, false)

    Open3.stub(:capture3, [ "", "libreoffice error", mock_status ]) do
      error = assert_raises(DocumentProcessor::ProcessingError) do
        @processor.convert_presentation_to_pdf("/tmp/slides.pptx")
      end
      assert_includes error.message, "libreoffice conversion failed"
    end
  end

  test "convert_presentation_to_pdf raises ProcessingError when pdf not found" do
    mock_status = Minitest::Mock.new
    mock_status.expect(:success?, true)

    Dir.mktmpdir do |tmpdir|
      pptx_path = File.join(tmpdir, "slides.pptx")
      FileUtils.touch(pptx_path)

      Open3.stub(:capture3, [ "", "", mock_status ]) do
        error = assert_raises(DocumentProcessor::ProcessingError) do
          @processor.convert_presentation_to_pdf(pptx_path)
        end
        assert_includes error.message, "PDF output not found"
      end
    end
  end
end
