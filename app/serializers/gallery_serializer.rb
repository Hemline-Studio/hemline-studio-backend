class GallerySerializer
  def initialize(gallery)
    @gallery = gallery
  end

  def as_json(context: :summary)
    base = {
      id: @gallery.id,
      file_name: @gallery.file_name,
      description: @gallery.description,
      url: @gallery.url,
      public_id: @gallery.public_id,
      folder_ids: @gallery.folder_ids_array,
      created_at: @gallery.created_at&.iso8601
    }

    # Add metadata based on context
    if context == :detailed
      base[:meta] = {
        width: @gallery.width,
        height: @gallery.height,
        aperture: @gallery.aperture,
        camera_model: @gallery.camera_model,
        shutter_speed: @gallery.shutter_speed,
        iso: @gallery.iso
      }
    elsif @gallery.width.present? || @gallery.height.present?
      # For summary, only include width and height if available
      base[:meta] = {
        width: @gallery.width,
        height: @gallery.height
      }
    end

    base
  end

  def to_json(*args)
    as_json.to_json(*args)
  end
end
