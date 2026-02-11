class CreateGithubAuthentications < ActiveRecord::Migration[8.1]
  def change
    create_table :github_authentications do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :uid, null: false, index: { unique: true }
      t.string :nickname, null: false
      t.string :name
      t.string :email
      t.string :avatar_url

      t.timestamps
    end
  end
end
