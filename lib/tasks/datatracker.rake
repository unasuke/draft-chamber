# frozen_string_literal: true

namespace :datatracker do
  desc "Import groups from IETF Datatracker (default: active working groups)"
  task import_groups: :environment do
    params = {}
    params[:state] = ENV.fetch("STATE", "active")
    params[:type] = ENV["TYPE"] if ENV["TYPE"]

    stats = DatatrackerImport::GroupImporter.new.import(params)
    puts "Groups: #{stats.inspect}"
  end

  desc "Import a meeting from IETF Datatracker. Usage: rake datatracker:import_meeting MEETING=124"
  task import_meeting: :environment do
    number = ENV.fetch("MEETING") { abort "Set MEETING=<number> (e.g., MEETING=124)" }
    stats = DatatrackerImport::MeetingImporter.new.import(number: number)
    puts "Meeting: #{stats.inspect}"
  end

  desc "Import sessions for a meeting. Usage: rake datatracker:import_sessions MEETING=124"
  task import_sessions: :environment do
    number = ENV.fetch("MEETING") { abort "Set MEETING=<number>" }
    stats = DatatrackerImport::SessionImporter.new.import(meeting_number: number)
    puts "Sessions: #{stats.inspect}"
  end

  desc "Import session presentations (and their documents) for a meeting. Usage: rake datatracker:import_presentations MEETING=124 [GROUP=tls]"
  task import_presentations: :environment do
    number = ENV.fetch("MEETING") { abort "Set MEETING=<number>" }
    group = ENV["GROUP"]
    stats = DatatrackerImport::SessionPresentationImporter.new
      .import(meeting_number: number, group_acronym: group)
    puts "Presentations: #{stats.inspect}"
  end

  desc "Full import for a meeting. Usage: rake datatracker:import_all MEETING=124"
  task import_all: :environment do
    number = ENV.fetch("MEETING") { abort "Set MEETING=<number>" }
    results = DatatrackerImport::FullImport.new.import_meeting(meeting_number: number)
    results.each { |k, v| puts "#{k}: #{v.inspect}" }
  end

  desc "Delete all resources for a meeting. Usage: rake datatracker:delete_meeting MEETING=124"
  task delete_meeting: :environment do
    number = ENV.fetch("MEETING") { abort "Set MEETING=<number> (e.g., MEETING=124)" }
    meeting = Meeting.find_by!(number: number)

    document_ids = Document.joins(:session_presentations)
      .where(session_presentations: { session_id: meeting.session_ids })
      .distinct
      .pluck(:id)

    sessions_count = meeting.sessions.count
    presentations_count = SessionPresentation.where(session_id: meeting.session_ids).count

    # Destroying the meeting cascades to sessions and session_presentations
    meeting.destroy!

    # Delete documents that are now orphaned (no remaining session_presentations)
    orphaned_ids = document_ids - SessionPresentation.where(document_id: document_ids).distinct.pluck(:document_id)
    orphaned_documents_count = Document.where(id: orphaned_ids).destroy_all.count

    puts "Deleted meeting #{number}:"
    puts "  Sessions: #{sessions_count}"
    puts "  Session presentations: #{presentations_count}"
    puts "  Orphaned documents removed: #{orphaned_documents_count}"
    puts "  Documents retained (shared with other meetings): #{document_ids.size - orphaned_documents_count}"
  end
end
