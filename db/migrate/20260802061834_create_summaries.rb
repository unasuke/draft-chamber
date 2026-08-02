# frozen_string_literal: true

class CreateSummaries < ActiveRecord::Migration[8.1]
  def change
    create_table :summaries do |t|
      t.references :session, null: true, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :oauth_application, null: true,
                   foreign_key: { to_table: :oauth_applications, on_delete: :nullify }
      t.string :client_name, null: false
      t.string :meeting_number, null: false
      t.string :group_acronym
      t.string :title, null: false
      t.text :body, null: false
      t.string :public_token, null: false

      t.timestamps
    end

    add_index :summaries, :public_token, unique: true
  end
end
