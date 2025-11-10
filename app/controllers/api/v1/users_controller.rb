class Api::V1::UsersController < Api::V1::BaseController
  include UserDataConcern

  before_action :authenticate_user!
  before_action :set_user, only: [ :update, :update_business_image ]

  # PATCH/PUT /api/v1/users/profile
  def update
    # Store the old onboarding status before updating
    was_not_onboarded = @user.has_onboarded == false

    if @user.update(user_update_params)
      # Check if user just completed onboarding
      if was_not_onboarded && @user.has_onboarded == true
        # Send welcome email
        begin
          EmailService.send_welcome_email(@user)
        rescue StandardError => e
          Rails.logger.error "Failed to send welcome email: #{e.message}"
        end
      end
      render json: {
        success: true,
        data: user_data(@user),
        message: "User updated successfully"
      }
    else
      render json: {
        success: false,
        errors: @user.errors.full_messages,
        message: "Failed to update user"
      }, status: :unprocessable_content
    end
  end

  # PATCH/PUT /api/v1/users/business_image
  def update_business_image
    unless params[:image].present?
      render json: {
        success: false,
        message: "No image provided",
        errors: [ "image parameter is required" ]
      }, status: :bad_request
      return
    end

    begin
      # Delete old image from Cloudinary if exists
      if @user.business_image_public_id.present?
        begin
          Cloudinary::Uploader.destroy(@user.business_image_public_id)
        rescue StandardError => e
          Rails.logger.error "Failed to delete old business image from Cloudinary: #{e.message}"
        end
      end

      # Upload new image to Cloudinary
      result = Cloudinary::Uploader.upload(
        params[:image].tempfile,
        folder: "tailor_app/business_images/#{@user.id}",
        resource_type: :image,
        transformation: [
          {
            width: 500,
            height: 500,
            crop: "limit",
            quality: "auto:good",
            fetch_format: "webp"
          }
        ]
      )

      # Update user with new image details
      if @user.update(
        business_image: result["secure_url"],
        business_image_public_id: result["public_id"]
      )
        render json: {
          success: true,
          data: user_data(@user),
          message: "Business image updated successfully"
        }
      else
        render json: {
          success: false,
          errors: @user.errors.full_messages,
          message: "Failed to update business image"
        }, status: :unprocessable_content
      end
    rescue StandardError => e
      render json: {
        success: false,
        message: "Failed to upload image",
        errors: [ e.message ]
      }, status: :unprocessable_content
    end
  end

  private

  def set_user
    @user = current_user
  end

  def user_update_params
    params.require(:user).permit(
      :first_name,
      :last_name,
      :profession,
      :business_name,
      :business_address,
      :has_onboarded,
      skills: []
    )
  end
end
