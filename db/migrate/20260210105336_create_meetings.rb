# frozen_string_literal: true

class CreateMeetings < ActiveRecord::Migration[8.1]
  def change
    create_table :meetings do |t|
      t.string :number, null: false
      t.string :meeting_type
      t.date :date
      t.integer :days, default: 7
      t.string :city
      t.string :country
      t.string :time_zone
      t.string :venue_name
      t.integer :attendees
      t.string :resource_uri, null: false

      t.timestamps
    end

    add_index :meetings, :number, unique: true
    add_index :meetings, :resource_uri, unique: true
    add_index :meetings, :meeting_type
    add_index :meetings, :date
  end
end
