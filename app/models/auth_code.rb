class AuthCode < ApplicationRecord
  belongs_to :user

  validates :code, presence: true, uniqueness: true
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :valid_codes, -> { where(used_at: nil).where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }
  scope :used, -> { where.not(used_at: nil) }

  def expired?
    expires_at <= Time.current
  end

  def used?
    used_at.present?
  end

  def valid_code?
    !expired? && !used?
  end

  def use!
    update!(used_at: Time.current)
  end

  def magic_link(base_url)
    "#{base_url}/verify-magic-link?token=#{token}"
  end
end
