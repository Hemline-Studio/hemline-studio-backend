class FolderSerializer
  def initialize(folder)
    @folder = folder
  end

  def as_json
    {
      id: @folder.id,
      name: @folder.name,
      description: @folder.description,
      imageIds: @folder.image_ids_array,
      coverImage: @folder.cover_image,
      createdAt: @folder.created_at&.iso8601
    }
  end

  def to_json(*args)
    as_json.to_json(*args)
  end
end
