class Api::V1::PublicFoldersController < ApplicationController
  # No authentication required for public folders

  # GET /api/v1/public/folders/:public_id
  def show
    folder = Folder.find_by_public_id(params[:public_id])

    unless folder
      render json: {
        message: "Folder not found or is not public",
        errors: [ "Invalid public_id or folder is private" ]
      }, status: :not_found
      return
    end

    # Get first 20 images
    images = folder.images.order(created_at: :desc).limit(20)
    total_images = folder.image_count

    folder_data = FolderSerializer.new(folder).as_json
    images_data = images.map { |image| GallerySerializer.new(image).as_json }

    render json: {
      message: "Public folder retrieved successfully",
      data: {
        folder: folder_data,
        user: {
          id: folder.user.id,
          first_name: folder.user.first_name,
          last_name: folder.user.last_name,
          full_name: folder.user.full_name,
          business_name: folder.user.business_name,
          business_address: folder.user.business_address,
          business_image: folder.user.business_image,
          profession: folder.user.profession,
          phone_number: folder.user.phone_number,
          email: folder.user.email,
          skills: folder.user.skills
        },
        images: images_data,
        pagination: {
          total: total_images,
          count: images.count,
          per_page: 20,
          current_page: 1,
          total_pages: (total_images.to_f / 20).ceil,
          has_more: total_images > 20
        }
      }
    }, status: :ok
  end

  # GET /api/v1/public/folders/:public_id/images
  def images
    folder = Folder.find_by_public_id(params[:public_id])

    unless folder
      render json: {
        message: "Folder not found or is not public",
        errors: [ "Invalid public_id or folder is private" ]
      }, status: :not_found
      return
    end

    # Pagination
    page = params[:page]&.to_i || 1
    per_page = [ params[:per_page]&.to_i || 20, 50 ].min

    images = folder.images.order(created_at: :desc)
    total_images = folder.image_count

    # Manual pagination
    offset = (page - 1) * per_page
    paginated_images = images.offset(offset).limit(per_page)

    images_data = paginated_images.map { |image| GallerySerializer.new(image).as_json }

    render json: {
      message: "Images retrieved successfully",
      data: {
        images: images_data,
        user: {
          id: folder.user.id,
          first_name: folder.user.first_name,
          last_name: folder.user.last_name,
          full_name: folder.user.full_name,
          business_name: folder.user.business_name,
          business_image: folder.user.business_image,
          business_address: folder.user.business_address,
          profession: folder.user.profession,
          phone_number: folder.user.phone_number,
          email: folder.user.email,
          skills: folder.user.skills
        }
      },
      pagination: {
      total: total_images,
      count: paginated_images.count,
      per_page: per_page,
      current_page: page,
      total_pages: (total_images.to_f / per_page).ceil,
      has_more: (page * per_page) < total_images
      }
    }, status: :ok
  end
end
