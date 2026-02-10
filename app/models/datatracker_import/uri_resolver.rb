# frozen_string_literal: true

module DatatrackerImport
  class UriResolver
    def self.resolve(uri, model_class)
      return nil if uri.blank?
      model_class.find_by!(resource_uri: uri)
    end

    def self.resolve_optional(uri, model_class)
      return nil if uri.blank?
      model_class.find_by(resource_uri: uri)
    end
  end
end
