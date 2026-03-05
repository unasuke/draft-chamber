# frozen_string_literal: true

module Datatracker
  module Resources
    class NewRevisionDocEvent < Base
      def for_document(document_name, params = {})
        list(params.merge(doc__name: document_name))
      end

      def since(document_name, event_id, params = {})
        list(params.merge(doc__name: document_name, id__gt: event_id))
      end

      private

      def endpoint
        "/api/v1/doc/newrevisiondocevent/"
      end
    end
  end
end
