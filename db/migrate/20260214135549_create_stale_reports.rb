# frozen_string_literal: true

class CreateStaleReports < ActiveRecord::Migration[8.1]
  def change
    create_table :stale_reports do |t|
      t.references :reportable, polymorphic: true, null: false
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.text :message

      t.timestamps
    end

    add_index :stale_reports, :status
    add_index :stale_reports, [ :reportable_type, :reportable_id, :user_id, :status ],
              name: "index_stale_reports_on_reportable_user_status"
  end
end
