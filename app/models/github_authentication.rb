# frozen_string_literal: true

class GithubAuthentication < ApplicationRecord
  belongs_to :user

  validates :uid, presence: true, uniqueness: true
  validates :nickname, presence: true
end
