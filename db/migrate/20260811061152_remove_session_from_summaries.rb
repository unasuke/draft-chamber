# frozen_string_literal: true

class RemoveSessionFromSummaries < ActiveRecord::Migration[8.1]
  def change
    remove_reference :summaries, :session, foreign_key: true, index: true
  end
end
