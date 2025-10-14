class User < ApplicationRecord
  # Use UUID as primary key
  self.primary_key = :id

  has_many :auth_codes, dependent: :destroy
  has_many :clients, dependent: :destroy
  has_many :custom_fields, dependent: :destroy
  has_many :folders, dependent: :destroy
  has_many :galleries, dependent: :destroy

  # Define profession choices
  PROFESSION_CHOICES = [
    "Tailors / Dressmakers",
    "Fashion Designers",
    "Costume Designers (Theater/Film/TV)",
    "Seamstresses",
    "Medical Garment Makers"
  ].freeze

  # Define skills choices
  SKILLS_CHOICES = [
    "Fashion Designing",
    "Textile Design",
    "Costume Design",
    "Fashion Illustration",
    "Fashion Stylist",
    "Pattern Maker",
    "Bespoke Tailoring",
    "Shoemaking",
    "Bag Designing",
    "Wardrobe Consultant",
    "Sample Maker",
    "CAD Fashion Designer",
    "Seamstress"
  ].freeze

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :profession, inclusion: { in: PROFESSION_CHOICES }, allow_nil: true
  validate :skills_must_be_from_choices
  # first_name and last_name are optional now so users can sign up with email only
  # business_name and business_address are optional

  before_save :downcase_email

  def full_name
    return nil if first_name.blank? && last_name.blank?
    [ first_name, last_name ].compact.join(" ").strip
  end

  def complete_onboarding!
    update!(has_onboarded: true)
  end

  def add_skill(skill)
    return false unless SKILLS_CHOICES.include?(skill)
    return false if skills.include?(skill)

    self.skills = (skills || []) + [ skill ]
    save
  end

  def remove_skill(skill)
    return false unless skills.include?(skill)

    self.skills = skills - [ skill ]
    save
  end

  def generate_auth_code!
    # Ensure no more than one active magic link: delete any existing unused codes,
    # then create a fresh one inside a transaction.
    ApplicationRecord.transaction do
      auth_codes.where(used_at: nil).delete_all

      # Generate new 6-digit code
      code = SecureRandom.random_number(100000..999999).to_s
      token = SecureRandom.urlsafe_base64(32)

      auth_codes.create!(
        code: code,
        token: token,
        expires_at: 15.minutes.from_now
      )
    end
  end

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end

  def skills_must_be_from_choices
    return if skills.blank?

    invalid_skills = skills - SKILLS_CHOICES
    if invalid_skills.any?
      errors.add(:skills, "contains invalid skills: #{invalid_skills.join(', ')}")
    end
  end
end
