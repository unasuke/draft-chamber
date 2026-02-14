# frozen_string_literal: true

class CreateStaleReportTool < MCP::Tool
  description "Report stale/outdated data for a meeting, document, or group"

  annotations(
    read_only_hint: false,
    destructive_hint: false,
    idempotent_hint: false,
    open_world_hint: false
  )

  input_schema(
    properties: {
      reportable_type: {
        type: "string",
        enum: %w[Meeting Document Group],
        description: "The type of resource to report as stale"
      },
      reportable_identifier: {
        type: "string",
        description: "The identifier of the resource: meeting number for Meeting, document name for Document, group acronym for Group"
      },
      message: {
        type: "string",
        description: "Optional description of what seems outdated"
      }
    },
    required: %w[reportable_type reportable_identifier]
  )

  class << self
    def call(server_context:, **params)
      user = server_context[:user]
      reportable = find_reportable(params[:reportable_type], params[:reportable_identifier])

      stale_report = StaleReport.new(
        reportable: reportable,
        user: user,
        message: params[:message]
      )

      if stale_report.save
        MCP::Tool::Response.new([ {
          type: "text",
          text: JSON.generate({
            id: stale_report.id,
            status: stale_report.status,
            reportable_type: stale_report.reportable_type,
            reportable_id: stale_report.reportable_id,
            message: stale_report.message,
            created_at: stale_report.created_at.iso8601
          })
        } ])
      else
        MCP::Tool::Response.new([ {
          type: "text",
          text: stale_report.errors.full_messages.to_sentence
        } ], error: true)
      end
    rescue ActiveRecord::RecordNotFound
      MCP::Tool::Response.new([ {
        type: "text",
        text: "Resource not found: #{params[:reportable_type]} '#{params[:reportable_identifier]}'"
      } ], error: true)
    end

    private

    def find_reportable(type, identifier)
      case type
      when "Meeting"
        Meeting.find_by!(number: identifier)
      when "Document"
        Document.find_by!(name: identifier)
      when "Group"
        Group.find_by!(acronym: identifier)
      end
    end
  end
end
