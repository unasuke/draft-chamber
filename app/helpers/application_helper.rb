module ApplicationHelper
  DATATRACKER_BASE_URL = "https://datatracker.ietf.org"

  def datatracker_meeting_url(meeting)
    return nil unless meeting.ietf?

    "#{DATATRACKER_BASE_URL}/meeting/#{meeting.number}/agenda/"
  end

  def datatracker_document_url(document)
    "#{DATATRACKER_BASE_URL}/doc/#{document.name}/"
  end

  def datatracker_meeting_session_url(meeting, group)
    "#{DATATRACKER_BASE_URL}/meeting/#{meeting.number}/session/#{group.acronym}/"
  end

  def datatracker_group_url(group)
    "#{DATATRACKER_BASE_URL}/group/#{group.acronym}/about/"
  end
end
