# frozen_string_literal: true

class CreateGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :groups do |t|
      t.string :acronym, null: false
      t.string :name
      t.string :group_type
      t.string :state
      t.text :description
      t.string :list_email
      t.string :list_archive
      t.references :parent, foreign_key: { to_table: :groups }, null: true
      t.string :resource_uri, null: false

      t.timestamps
    end

    add_index :groups, :acronym, unique: true
    add_index :groups, :resource_uri, unique: true
    add_index :groups, :state
    add_index :groups, :group_type
  end
end
