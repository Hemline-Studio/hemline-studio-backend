class Api::V1::Gallery::GalleriesController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :set_gallery, only: [ :show, :update ]

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
      data: GallerySerializer.new(@gallery).as_json
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
        data: GallerySerializer.new(@gallery.reload).as_json
      }, status: :ok
    else
      render json: {
        message: "Failed to update gallery image",
        errors: @gallery.errors.full_messages
      }, status: :unprocessable_entity
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

          # Delete the image
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
