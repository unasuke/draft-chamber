# frozen_string_literal: true

module DatatrackerImport
  class BaseImporter
    attr_reader :client, :stats

    def initialize(client: nil)
      @client = client || Datatracker::Client.new
      @stats = { created: 0, updated: 0, errors: 0 }
    end

    def import
      raise NotImplementedError
    end

    private

    def log(message)
      Rails.logger.info("[DatatrackerImport] #{message}")
      puts "[DatatrackerImport] #{message}" if $stdout.tty? && !Rails.env.test?
    end

    def fetch_all_pages(resource, params = {})
      all_objects = []
      response = resource.list(params.merge(limit: 100, offset: 0))
      all_objects.concat(response.objects)

      while response.next_page?
        response = resource.list(params.merge(
          limit: 100,
          offset: all_objects.size
        ))
        all_objects.concat(response.objects)
      end

      all_objects
    end

    def upsert_record(model_class, resource_uri:, attributes:)
      record = model_class.find_or_initialize_by(resource_uri: resource_uri)
      is_new = record.new_record?
      record.assign_attributes(attributes)
      record.save!

      if is_new
        @stats[:created] += 1
      else
        @stats[:updated] += 1
      end

      record
    rescue ActiveRecord::RecordInvalid => e
      @stats[:errors] += 1
      log("Error importing #{model_class.name} (#{resource_uri}): #{e.message}")
      nil
    end

    # Datatracker API may return type/state fields as URI strings
    # e.g., "/api/v1/name/groupstatename/active/" -> "active"
    def extract_name_from_uri(value)
      return value unless value.is_a?(String) && value.start_with?("/api/")
      value.split("/").compact_blank.last
    end
  end
end
