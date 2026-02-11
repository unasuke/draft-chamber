# frozen_string_literal: true

# RFC 8707: Resource Indicators for OAuth 2.0
# Adds resource column to bind tokens to their intended resource server (audience).
class AddResourceToDoorkeeperTokens < ActiveRecord::Migration[8.1]
  def change
    add_column :oauth_access_grants, :resource, :string
    add_column :oauth_access_tokens, :resource, :string
  end
end
