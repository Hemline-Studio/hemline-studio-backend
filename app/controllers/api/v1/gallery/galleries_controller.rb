class Api::V1::Gallery::GalleriesController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :set_gallery, only: [ :show, :update ]

  # POST /api/v1/gallery/galleries/upload
  def upload
    unless params[:images].present?
      render json: {
        message: "No images provided",
        errors: [ "images parameter is required" ]
      }, status: :bad_request
      return
    end

    images = params[:images]

    # Ensure images is an array
    images = [ images ] unless images.is_a?(Array)

    # Validate max 10 images
    if images.length > 10
      render json: {
        message: "Too many images",
        errors: [ "Maximum 10 images allowed per upload" ]
      }, status: :bad_request
      return
    end

    uploaded_images = []
    failed_uploads = []

    images.each_with_index do |image, index|
      begin
        # Upload to Cloudinary with compression, WebP format, and max 350px
        result = Cloudinary::Uploader.upload(
          image.tempfile,
          folder: "tailor_app/gallery/#{current_user.id}",
          resource_type: :image,
          transformation: [
            {
              quality: "auto:good", # Auto optimize quality
              fetch_format: "webp"  # Convert to WebP
            }
          ],
          exif: true # Request EXIF metadata
        )

        # Extract metadata from Cloudinary result
        metadata = {
          width: result["width"],
          height: result["height"],
          aperture: result.dig("exif", "ApertureValue"),
          camera_model: result.dig("exif", "Model"),
          shutter_speed: result.dig("exif", "ShutterSpeedValue"),
          iso: result.dig("exif", "ISO")
        }

        # Create gallery record
        gallery = current_user.galleries.create!(
          file_name: image.original_filename,
          url: result["secure_url"],
          public_id: result["public_id"],
          description: params[:descriptions]&.dig(index) || "",
          width: metadata[:width],
          height: metadata[:height],
          aperture: metadata[:aperture],
          camera_model: metadata[:camera_model],
          shutter_speed: metadata[:shutter_speed],
          iso: metadata[:iso]
        )

        uploaded_images << GallerySerializer.new(gallery).as_json
      rescue StandardError => e
        failed_uploads << {
          filename: image.original_filename,
          error: e.message
        }
      end
    end

    if failed_uploads.empty?
      render json: {
        message: "Images uploaded successfully",
        data: uploaded_images,
        count: uploaded_images.length
      }, status: :created
    elsif uploaded_images.empty?
      render json: {
        message: "All uploads failed",
        errors: failed_uploads
      }, status: :unprocessable_content
    else
      render json: {
        message: "Some images uploaded successfully",
        data: uploaded_images,
        errors: failed_uploads,
        successCount: uploaded_images.length,
        failedCount: failed_uploads.length
      }, status: :multi_status
    end
  end

  # GET /api/v1/gallery/galleries
  def index
    per_page = [ params[:per_page]&.to_i || 10, 50 ].min
    galleries = current_user.galleries.order(created_at: :desc)

    result = paginate_collection(galleries, per_page)

    galleries_data = result[:data].map do |gallery|
      GallerySerializer.new(gallery).as_json
    end

    render json: {
      message: "Gallery images retrieved successfully",
      data: galleries_data,
      pagination: result[:pagination]
    }, status: :ok
  end

  # GET /api/v1/gallery/galleries/:id
  def show
    render json: {
      message: "Gallery image retrieved successfully",
      data: GallerySerializer.new(@gallery).as_json(context: :detailed)
    }, status: :ok
  end

  # PATCH/PUT /api/v1/gallery/galleries/:id
  def update
    unless params[:gallery].present?
      render json: {
        message: "Gallery parameters are required",
        errors: [ "gallery parameter is required" ]
      }, status: :bad_request
      return
    end

    if @gallery.update(gallery_params)
      render json: {
        message: "Gallery image updated successfully",
        data: GallerySerializer.new(@gallery.reload).as_json(context: :detailed)
      }, status: :ok
    else
      render json: {
        message: "Failed to update gallery image",
        errors: @gallery.errors.full_messages
      }, status: :unprocessable_content
    end
  rescue ActionController::ParameterMissing => e
    render json: {
      message: "Required parameter missing",
      errors: [ e.message ]
    }, status: :bad_request
  end

  # DELETE /api/v1/gallery/galleries/:id
  # DELETE /api/v1/gallery/galleries (bulk delete)
  def destroy
    image_ids = params[:image_ids]

    # If image_ids are provided, do bulk delete
    if image_ids.present? && image_ids.is_a?(Array) && image_ids.any?
      # Validate that all images belong to the current user
      images = Gallery.where(id: image_ids, user: current_user)

      if images.count != image_ids.length
        render json: {
          message: "Some images not found or don't belong to you",
          errors: [ "Invalid image IDs provided" ]
        }, status: :not_found
        return
      end

      # Store count before destroying
      deleted_count = images.count

      # Remove images from all folders they belong to
      ActiveRecord::Base.transaction do
        images.each do |image|
          # Get all folders that contain this image
          folders = current_user.folders.where("? = ANY(image_ids)", image.id)

          # Remove image from each folder
          folders.each do |folder|
            folder.remove_image(image.id)
          end

          # Delete from Cloudinary
          begin
            Cloudinary::Uploader.destroy(image.public_id) if image.public_id.present?
          rescue StandardError => e
            Rails.logger.error "Failed to delete image from Cloudinary: #{e.message}"
            # Continue with database deletion even if Cloudinary deletion fails
          end

          # Delete the image from database
          image.destroy
        end
      end

      render json: {
        message: "Images deleted successfully",
        count: deleted_count
      }, status: :ok
    # Single delete
    elsif @gallery.present?
      # Remove image from all folders it belongs to
      ActiveRecord::Base.transaction do
        folders = current_user.folders.where("? = ANY(image_ids)", @gallery.id)

        folders.each do |folder|
          folder.remove_image(@gallery.id)
        end

        # Delete from Cloudinary
        begin
          Cloudinary::Uploader.destroy(@gallery.public_id) if @gallery.public_id.present?
        rescue StandardError => e
          Rails.logger.error "Failed to delete image from Cloudinary: #{e.message}"
          # Continue with database deletion even if Cloudinary deletion fails
        end

        @gallery.destroy
      end

      render json: {
        message: "Gallery image deleted successfully"
      }, status: :ok
    else
      render json: {
        message: "Image IDs are required for bulk delete",
        errors: [ "image_ids parameter is required" ]
      }, status: :bad_request
    end
  end

  private

  def set_gallery
    @gallery = current_user.galleries.find_by(id: params[:id])

    unless @gallery
      render json: {
        message: "Gallery image not found",
        errors: [ "Gallery image with ID #{params[:id]} not found" ]
      }, status: :not_found
      false  # This stops the before_action chain
    end
  end

  def gallery_params
    params.require(:gallery).permit(:file_name, :description)
  end
end
