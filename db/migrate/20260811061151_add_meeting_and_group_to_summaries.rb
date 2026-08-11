# frozen_string_literal: true

class AddMeetingAndGroupToSummaries < ActiveRecord::Migration[8.1]
  def up
    add_reference :summaries, :meeting, null: true, foreign_key: true
    add_reference :summaries, :group, null: true, foreign_key: true

    execute <<~SQL
      UPDATE summaries
      SET meeting_id = (SELECT meeting_id FROM sessions WHERE sessions.id = summaries.session_id),
          group_id   = (SELECT group_id   FROM sessions WHERE sessions.id = summaries.session_id)
      WHERE session_id IS NOT NULL
    SQL
  end

  def down
    remove_reference :summaries, :group, foreign_key: true
    remove_reference :summaries, :meeting, foreign_key: true
  end
end
