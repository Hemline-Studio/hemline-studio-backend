class FolderSerializer
  def initialize(folder)
    @folder = folder
  end

  def as_json
    {
      id: @folder.id,
      name: @folder.name,
      description: @folder.description,
      image_ids: @folder.image_ids_array,
      cover_image: @folder.cover_image,
      created_at: @folder.created_at&.iso8601,
      folder_color: @folder.folder_color
    }
  end

  def to_json(*args)
    as_json.to_json(*args)
  end
end
