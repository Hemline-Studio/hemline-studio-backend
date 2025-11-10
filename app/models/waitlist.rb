class Waitlist < ApplicationRecord
  # Use UUID as primary key
  self.primary_key = :id

  validates :email, presence: true,
    uniqueness: { case_sensitive: false },
    format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }

  before_save :downcase_email

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end
end
