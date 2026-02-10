# frozen_string_literal: true

module Datatracker
  module Resources
    class Document < Base
      def find_by_name(name)
        response = client.get("#{endpoint}#{name}/")
        handle_response(response)
      end

      def search(query, params = {})
        list(params.merge(name__contains: query))
      end

      def drafts(params = {})
        list(params.merge(type: "draft"))
      end

      def rfcs(params = {})
        list(params.merge(type: "rfc"))
      end

      def slides(params = {})
        list(params.merge(type: "slides"))
      end

      def for_group(group_acronym, params = {})
        list(params.merge(group__acronym: group_acronym))
      end

      def material_url(document_name, meeting_number)
        "#{client.config.base_url}/meeting/#{meeting_number}/materials/#{document_name}/"
      end

      private

      def endpoint
        "/api/v1/doc/document/"
      end
    end
  end
end
