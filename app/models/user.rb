# frozen_string_literal: true

class User < ApplicationRecord
  enum :role, {
    general: "general",
    admin: "admin"
  }

  has_one :github_authentication, dependent: :destroy

  delegate :nickname, :name, :email, :avatar_url, to: :github_authentication, allow_nil: true

  def self.find_or_create_from_omniauth(auth)
    github_auth = GithubAuthentication.find_by(uid: auth.uid)
    if github_auth
      github_auth.update!(
        nickname: auth.info.nickname,
        name: auth.info.name,
        email: auth.info.email,
        avatar_url: auth.info.image
      )
      github_auth.user
    else
      user = create!
      user.create_github_authentication!(
        uid: auth.uid,
        nickname: auth.info.nickname,
        name: auth.info.name,
        email: auth.info.email,
        avatar_url: auth.info.image
      )
      user
    end
  end
end
