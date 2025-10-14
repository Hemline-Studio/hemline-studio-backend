class Api::V1::Gallery::FoldersController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :set_folder, only: [ :show, :update, :destroy, :add_image, :remove_images, :set_cover_image ]

  # GET /api/v1/gallery/folders
  def index
    per_page = [ params[:per_page]&.to_i || 10, 50 ].min
    folders = current_user.folders.order(created_at: :desc)

    result = paginate_collection(folders, per_page)

    folders_data = result[:data].map do |folder|
      FolderSerializer.new(folder).as_json
    end

    render json: {
      message: "Folders retrieved successfully",
      data: folders_data,
      pagination: result[:pagination]
    }, status: :ok
  end

  # GET /api/v1/gallery/folders/:id
  def show
    per_page = [ params[:per_page]&.to_i || 10, 50 ].min
    images = @folder.images.order(created_at: :desc)

    result = paginate_collection(images, per_page)

    folder_data = FolderSerializer.new(@folder).as_json
    images_data = result[:data].map { |image| GallerySerializer.new(image).as_json }

    render json: {
      folder: folder_data,
      images: images_data,
      pagination: result[:pagination]
    }, status: :ok
  end

  # POST /api/v1/gallery/folders
  def create
    unless params[:folder].present?
      render json: {
        message: "Folder parameters are required",
        errors: [ "folder parameter is required" ]
      }, status: :bad_request
      return
    end

    folder = current_user.folders.build(folder_params)

    if folder.save
      # Add images to folder if image_ids are provided
      if params[:image_ids].present? && params[:image_ids].is_a?(Array)
        image_ids = params[:image_ids]

        # Validate that all images belong to the current user
        images = Gallery.where(id: image_ids, user: current_user)

        if images.count == image_ids.length
          # Add images to folder and folder to images
          ActiveRecord::Base.transaction do
            folder.add_images(image_ids)

            images.each do |image|
              image.add_to_folder(folder.id)
            end
          end
        end
      end

      render json: {
        message: "Folder created successfully",
        data: FolderSerializer.new(folder.reload).as_json
      }, status: :created
    else
      render json: {
        message: "Failed to create folder",
        errors: folder.errors.full_messages
      }, status: :unprocessable_entity
    end
  rescue ActionController::ParameterMissing => e
    render json: {
      message: "Required parameter missing",
      errors: [ e.message ]
    }, status: :bad_request
  end

  # PATCH/PUT /api/v1/gallery/folders/:id
  def update
    unless params[:folder].present?
      render json: {
        message: "Folder parameters are required",
        errors: [ "folder parameter is required" ]
      }, status: :bad_request
      return
    end

    if @folder.update(folder_params)
      # Update cover image if provided
      if params[:cover_image].present?
        cover_image_id = params[:cover_image]

        # Validate that the image belongs to the current user
        image = Gallery.find_by(id: cover_image_id, user: current_user)

        if image && @folder.has_image?(cover_image_id)
          @folder.update(cover_image: cover_image_id)
        elsif image && !@folder.has_image?(cover_image_id)
          render json: {
            message: "Image is not in this folder",
            errors: [ "Cover image must be one of the images in the folder" ]
          }, status: :bad_request
          return
        elsif !image
          render json: {
            message: "Image not found or doesn't belong to you",
            errors: [ "Invalid cover image ID provided" ]
          }, status: :not_found
          return
        end
      end

      render json: {
        message: "Folder updated successfully",
        data: FolderSerializer.new(@folder.reload).as_json
      }, status: :ok
    else
      render json: {
        message: "Failed to update folder",
        errors: @folder.errors.full_messages
      }, status: :unprocessable_entity
    end
  rescue ActionController::ParameterMissing => e
    render json: {
      message: "Required parameter missing",
      errors: [ e.message ]
    }, status: :bad_request
  end

  # DELETE /api/v1/gallery/folders/:id
  def destroy
    # Remove folder reference from all images in this folder
    Gallery.where(user: current_user)
           .where("? = ANY(folder_ids)", @folder.id)
           .find_each do |image|
      image.remove_from_folder(@folder.id)
    end

    @folder.destroy
    render json: {
      message: "Folder deleted successfully"
    }, status: :ok
  end

  # POST /api/v1/gallery/folders/:id/add_image
  def add_image
    image_ids = params[:image_ids]
    folder_ids = params[:folder_ids] || [ @folder.id ]

    if image_ids.blank?
      render json: {
        message: "Image IDs are required",
        errors: [ "image_ids parameter is required" ]
      }, status: :bad_request
      return
    end

    if folder_ids.blank?
      render json: {
        message: "Folder IDs are required",
        errors: [ "folder_ids parameter is required" ]
      }, status: :bad_request
      return
    end

    # Validate that all images belong to the current user
    images = Gallery.where(id: image_ids, user: current_user)

    if images.count != image_ids.length
      render json: {
        message: "Some images not found or don't belong to you",
        errors: [ "Invalid image IDs provided" ]
      }, status: :not_found
      return
    end

    # Validate that all folders belong to the current user
    folders = current_user.folders.where(id: folder_ids)

    if folders.count != folder_ids.length
      render json: {
        message: "Some folders not found or don't belong to you",
        errors: [ "Invalid folder IDs provided" ]
      }, status: :not_found
      return
    end

    # Add images to folders and folders to images
    ActiveRecord::Base.transaction do
      images.each do |image|
        image.add_to_folders(folder_ids)
      end

      folders.each do |folder|
        folder.add_images(image_ids)
      end
    end

    render json: {
      message: "Images added to folders successfully"
    }, status: :ok
  end

  # DELETE /api/v1/gallery/folders/:id/remove_images
  def remove_images
    image_ids = params[:image_ids]

    if image_ids.blank? || !image_ids.is_a?(Array) || image_ids.empty?
      render json: {
        message: "Image IDs are required",
        errors: [ "image_ids parameter must be a non-empty array" ]
      }, status: :bad_request
      return
    end

    # Validate that all images belong to the current user and are in this folder
    images = Gallery.where(id: image_ids, user: current_user)

    if images.count != image_ids.length
      render json: {
        message: "Some images not found or don't belong to you",
        errors: [ "Invalid image IDs provided" ]
      }, status: :not_found
      return
    end

    # Remove images from folder and folder from images
    ActiveRecord::Base.transaction do
      @folder.remove_images(image_ids)

      images.each do |image|
        image.remove_from_folder(@folder.id)
      end
    end

    render json: {
      message: "Images removed from folder successfully"
    }, status: :ok
  end

  # PATCH /api/v1/gallery/folders/:id/set_cover_image
  def set_cover_image
    image_id = params[:image_id]

    if image_id.blank?
      render json: {
        message: "Image ID is required",
        errors: [ "image_id parameter is required" ]
      }, status: :bad_request
      return
    end

    # Validate that the image belongs to the current user and is in this folder
    image = Gallery.find_by(id: image_id, user: current_user)

    unless image
      render json: {
        message: "Image not found or doesn't belong to you",
        errors: [ "Invalid image ID provided" ]
      }, status: :not_found
      return
    end

    unless @folder.has_image?(image_id)
      render json: {
        message: "Image is not in this folder",
        errors: [ "Image must be in the folder to set as cover" ]
      }, status: :bad_request
      return
    end

    if @folder.set_cover_image(image_id)
      render json: {
        message: "Cover image set successfully",
        data: FolderSerializer.new(@folder.reload).as_json
      }, status: :ok
    else
      render json: {
        message: "Failed to set cover image",
        errors: @folder.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def set_folder
    @folder = current_user.folders.find_by(id: params[:id])

    unless @folder
      render json: {
        message: "Folder not found",
        errors: [ "Folder with ID #{params[:id]} not found" ]
      }, status: :not_found
      false  # This stops the before_action chain
    end
  end

  def folder_params
    params.require(:folder).permit(:name, :description)
  end
end
