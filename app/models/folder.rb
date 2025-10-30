# == Schema Information
#
# Table name: folders
#
#  id            :uuid             not null, primary key
#  name          :string           not null
#  description   :text
#  image_ids     :text             default([]), array
#  cover_image   :string
#  folder_color  :integer          not null, default: random(1-9)
#  is_public     :boolean          default(false), not null
#  public_id     :string
#  user_id       :uuid             not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class Folder < ApplicationRecord
  belongs_to :user

  # Validations
  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :cover_image, inclusion: { in: ->(folder) { folder.image_ids_array } }, allow_blank: true
  validates :folder_color, presence: true, inclusion: { in: 1..9, message: "must be between 1 and 9" }
  validates :public_id, uniqueness: true, allow_blank: true

  # Callbacks
  before_save :ensure_cover_image_in_images
  before_validation :set_default_folder_color, on: :create
  before_save :generate_public_id, if: :is_public_changed_to_true?

  # Scopes
  scope :public_folders, -> { where(is_public: true) }
  scope :private_folders, -> { where(is_public: false) }

  # Instance methods
  def image_ids_array
    image_ids || []
  end

  def images
    return Gallery.none if image_ids_array.empty?

    Gallery.where(id: image_ids_array, user: user)
  end

  def image_count
    image_ids_array.length
  end

  def add_image(image_id)
    return if has_image?(image_id)

    self.image_ids = image_ids_array + [ image_id ]
    save
  end

  def remove_image(image_id)
    return unless has_image?(image_id)

    self.image_ids = image_ids_array - [ image_id ]

    # Clear cover image if it's being removed
    self.cover_image = nil if cover_image == image_id

    save
  end

  def add_images(image_ids_to_add)
    new_image_ids = (image_ids_array + image_ids_to_add).uniq
    update(image_ids: new_image_ids)
  end

  def remove_images(image_ids_to_remove)
    new_image_ids = image_ids_array - image_ids_to_remove

    # Clear cover image if it's being removed
    new_cover_image = image_ids_to_remove.include?(cover_image) ? nil : cover_image

    update(image_ids: new_image_ids, cover_image: new_cover_image)
  end

  def has_image?(image_id)
    image_ids_array.include?(image_id)
  end

  def set_cover_image(image_id)
    return false unless has_image?(image_id)

    update(cover_image: image_id)
  end

  def cover_image_object
    return nil unless cover_image

    Gallery.find_by(id: cover_image, user: user)
  end

  # Class methods
  def self.with_image(image_id)
    where("? = ANY(image_ids)", image_id)
  end

  def self.empty_folders
    where(image_ids: [])
  end

  def self.find_by_public_id(public_id)
    find_by(public_id: public_id, is_public: true)
  end

  # Public sharing methods
  def make_public!
    update!(is_public: true)
  end

  def make_private!
    update!(is_public: false, public_id: nil)
  end

  def public_url(base_url = "https://hemline.app")
    return nil unless is_public? && public_id.present?
    "#{base_url}/folders/#{public_id}"
  end

  private

  def ensure_cover_image_in_images
    if cover_image.present? && !image_ids_array.include?(cover_image)
      self.cover_image = nil
    end
  end

  def set_default_folder_color
    self.folder_color ||= rand(1..9)
  end

  def is_public_changed_to_true?
    is_public? && (is_public_changed? || public_id.blank?)
  end

  def generate_public_id
    loop do
      self.public_id = SecureRandom.urlsafe_base64(12)
      break unless Folder.exists?(public_id: public_id)
    end
  end
end
