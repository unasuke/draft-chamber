# frozen_string_literal: true

require "test_helper"

class BackfillSlideTextJobTest < ActiveSupport::TestCase
  setup do
    @original_throttle_duration = BackfillSlideTextJob::THROTTLE_DURATION
    BackfillSlideTextJob.send(:remove_const, :THROTTLE_DURATION)
    BackfillSlideTextJob.const_set(:THROTTLE_DURATION, 0)
  end

  teardown do
    BackfillSlideTextJob.send(:remove_const, :THROTTLE_DURATION)
    BackfillSlideTextJob.const_set(:THROTTLE_DURATION, @original_throttle_duration)
  end

  test "processes at most BATCH_SIZE materials per run" do
    (BackfillSlideTextJob::BATCH_SIZE + 3).times { |i| create_pending_material(i) }

    assert_equal BackfillSlideTextJob::BATCH_SIZE, record_processed_ids.size
  end

  test "processes the most recently downloaded materials first" do
    oldest = create_pending_material(1, downloaded_at: 3.days.ago)
    newest = create_pending_material(2, downloaded_at: 1.hour.ago)
    middle = create_pending_material(3, downloaded_at: 1.day.ago)

    assert_equal [ newest.id, middle.id, oldest.id ], record_processed_ids
  end

  test "keeps going after a material fails" do
    failing = create_pending_material(1, downloaded_at: 1.hour.ago)
    following = create_pending_material(2, downloaded_at: 2.hours.ago)

    processed = []
    extract_stub = ->(material_id) {
      raise Errno::ECONNRESET, "connection reset" if material_id == failing.id

      processed << material_id
    }

    ExtractSlideTextJob.stub(:perform_now, extract_stub) do
      assert_nothing_raised { BackfillSlideTextJob.perform_now }
    end

    assert_equal [ following.id ], processed
  end

  test "does nothing when no material is pending" do
    ExtractSlideTextJob.stub(:perform_now, ->(*) { flunk("nothing to extract") }) do
      assert_nothing_raised { BackfillSlideTextJob.perform_now }
    end
  end

  private

  def record_processed_ids
    processed = []

    ExtractSlideTextJob.stub(:perform_now, ->(material_id) { processed << material_id }) do
      BackfillSlideTextJob.perform_now
    end

    processed
  end

  def create_pending_material(index, downloaded_at: index.hours.ago)
    document = Document.create!(
      name: "slides-124-backfill-#{index}",
      document_type: :slides,
      resource_uri: "/api/v1/doc/document/slides-124-backfill-#{index}/"
    )

    DocumentMaterial.create!(
      document: document,
      download_status: :pending,
      content_type: DocumentMaterial::PDF_CONTENT_TYPE,
      processing_status: :processing_completed,
      downloaded_at: downloaded_at
    )
  end
end
