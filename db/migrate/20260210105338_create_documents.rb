# frozen_string_literal: true

class CreateDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :documents do |t|
      t.string :name, null: false
      t.string :title
      t.string :document_type
      t.text :abstract
      t.string :rev
      t.integer :pages
      t.string :uploaded_filename
      t.references :group, foreign_key: true, null: true
      t.datetime :time
      t.datetime :expires
      t.string :resource_uri, null: false

      t.timestamps
    end

    add_index :documents, :name, unique: true
    add_index :documents, :resource_uri, unique: true
    add_index :documents, :document_type
  end
end
