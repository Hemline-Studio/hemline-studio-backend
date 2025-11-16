class Token < ApplicationRecord
  belongs_to :user

  enum :token_type, { access: "access", refresh: "refresh" }

  validates :token, presence: true, uniqueness: true
  validates :token_type, presence: true
  validates :expires_at, presence: true

  # A token is active if it hasn't expired. We delete token records to revoke them.
  scope :active, -> { where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }

  # Scopes for different token types
  scope :access_tokens, -> { where(token_type: "access") }
  scope :refresh_tokens, -> { where(token_type: "refresh") }

  def expired?
    expires_at <= Time.current
  end

  def active?
    !expired?
  end

  # Clean up expired tokens for a user
  def self.cleanup_expired_tokens(user)
    user.tokens.expired.destroy_all
  end

  # Revoke all tokens of a specific type for a user
  def self.revoke_user_tokens(user, token_type = nil)
    tokens = user.tokens
    tokens = tokens.where(token_type: token_type) if token_type
    tokens.destroy_all
  end
end
