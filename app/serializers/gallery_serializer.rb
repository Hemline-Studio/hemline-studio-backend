class GallerySerializer
  def initialize(gallery)
    @gallery = gallery
  end

  def as_json
    {
      id: @gallery.id,
      file_name: @gallery.filename,
      url: @gallery.url,
      public_id: @gallery.public_id,
      folder_ids: @gallery.folder_ids_array,
      created_at: @gallery.created_at&.iso8601
    }
  end

  def to_json(*args)
    as_json.to_json(*args)
  end
end
