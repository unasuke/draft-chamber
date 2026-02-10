# frozen_string_literal: true

class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions do |t|
      t.references :meeting, null: false, foreign_key: true
      t.references :group, null: true, foreign_key: true
      t.string :name
      t.string :purpose
      t.string :requested_duration
      t.boolean :on_agenda
      t.string :remote_instructions
      t.integer :attendees
      t.integer :datatracker_id
      t.string :resource_uri, null: false

      t.timestamps
    end

    add_index :sessions, :resource_uri, unique: true
    add_index :sessions, :datatracker_id, unique: true
  end
end
