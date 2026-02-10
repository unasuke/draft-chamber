# frozen_string_literal: true

class CreateSessionPresentations < ActiveRecord::Migration[8.1]
  def change
    create_table :session_presentations do |t|
      t.references :session, null: false, foreign_key: true
      t.references :document, null: false, foreign_key: true
      t.integer :order
      t.string :rev
      t.string :resource_uri, null: false

      t.timestamps
    end

    add_index :session_presentations, :resource_uri, unique: true
    add_index :session_presentations, [:session_id, :document_id], unique: true
  end
end
