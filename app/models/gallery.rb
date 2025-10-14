# == Schema Information
#
# Table name: galleries
#
#  id          :string           not null, primary key (16-character UUID)
#  filename    :string           not null
#  url         :string           not null
#  public_id   :string           not null
#  folder_ids  :text             default([]), array
#  user_id     :uuid             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Gallery < ApplicationRecord
  belongs_to :user

  # Validations
  validates :filename, presence: true
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp([ "http", "https" ]), message: "must be a valid URL" }
  validates :public_id, presence: true, uniqueness: { scope: :user_id }

  # Callbacks
  before_create :generate_uuid

  # Instance methods
  def folder_ids_array
    folder_ids || []
  end

  def in_folder?(folder_id)
    folder_ids_array.include?(folder_id)
  end

  def add_to_folder(folder_id)
    return if in_folder?(folder_id)

    self.folder_ids = folder_ids_array + [ folder_id ]
    save
  end

  def remove_from_folder(folder_id)
    return unless in_folder?(folder_id)

    self.folder_ids = folder_ids_array - [ folder_id ]
    save
  end

  def add_to_folders(folder_ids_to_add)
    new_folder_ids = (folder_ids_array + folder_ids_to_add).uniq
    update(folder_ids: new_folder_ids)
  end

  def remove_from_folders(folder_ids_to_remove)
    new_folder_ids = folder_ids_array - folder_ids_to_remove
    update(folder_ids: new_folder_ids)
  end

  # Class methods
  def self.in_folder(folder_id)
    where("? = ANY(folder_ids)", folder_id)
  end

  def self.without_folders
    where(folder_ids: [])
  end

  private

  def generate_uuid
    self.id = SecureRandom.hex(8) # Generates a 16-character hexadecimal string
  end
end
