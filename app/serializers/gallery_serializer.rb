class GallerySerializer
  def initialize(gallery)
    @gallery = gallery
  end

  def as_json
    {
      id: @gallery.id,
      filename: @gallery.filename,
      url: @gallery.url,
      public_id: @gallery.public_id,
      folderIds: @gallery.folder_ids_array,
      createdAt: @gallery.created_at&.iso8601
    }
  end

  def to_json(*args)
    as_json.to_json(*args)
  end
end
