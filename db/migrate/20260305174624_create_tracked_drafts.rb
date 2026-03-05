# frozen_string_literal: true

class CreateTrackedDrafts < ActiveRecord::Migration[8.1]
  def change
    create_table :tracked_drafts do |t|
      t.references :document, foreign_key: true
      t.string :draft_name, null: false
      t.string :status, null: false, default: "active"
      t.datetime :last_checked_at
      t.string :last_known_rev
      t.timestamps
    end

    add_index :tracked_drafts, :draft_name, unique: true
    add_index :tracked_drafts, :status
  end
end
