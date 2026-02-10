# frozen_string_literal: true

module DatatrackerImport
  class GroupImporter < BaseImporter
    def import(params = {})
      log("Importing groups...")

      objects = fetch_all_pages(client.groups, params)
      log("Fetched #{objects.size} groups from API")

      # Pass 1: Create/update all group records without parent
      objects.each do |obj|
        upsert_record(Group, resource_uri: obj["resource_uri"], attributes: {
          acronym: obj["acronym"],
          name: obj["name"],
          group_type: extract_name_from_uri(obj["type"]),
          state: extract_name_from_uri(obj["state"]),
          description: obj["description"],
          list_email: obj["list_email"],
          list_archive: obj["list_archive"]
        })
      end

      # Pass 2: Resolve parent references
      objects.each do |obj|
        next if obj["parent"].blank?

        group = Group.find_by(resource_uri: obj["resource_uri"])
        parent = UriResolver.resolve_optional(obj["parent"], Group)
        if group && parent && group.parent_id != parent.id
          group.update!(parent: parent)
        end
      end

      log("Groups import complete: #{stats}")
      stats
    end
  end
end
