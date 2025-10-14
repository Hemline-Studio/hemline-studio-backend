# == Schema Information
#
# Table name: folders
#
#  id           :uuid             not null, primary key
#  name         :string           not null
#  description  :text
#  image_ids    :text             default([]), array
#  cover_image  :string
#  user_id      :uuid             not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class Folder < ApplicationRecord
  belongs_to :user

  # Validations
  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :cover_image, inclusion: { in: ->(folder) { folder.image_ids_array } }, allow_blank: true

  # Callbacks
  before_save :ensure_cover_image_in_images

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

  private

  def ensure_cover_image_in_images
    if cover_image.present? && !image_ids_array.include?(cover_image)
      self.cover_image = nil
    end
  end
end
