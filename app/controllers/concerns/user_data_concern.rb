module UserDataConcern
  extend ActiveSupport::Concern

  private

  def user_data(user = nil)
    target_user = user || current_user

    return nil unless target_user

    serialized_custom_fields = []

    if !target_user.custom_fields.blank?
      serialized_custom_fields = target_user.custom_fields.map do |field|
        CustomFieldSerializer.new(field).serializable_hash
      end
    end

    {
      id: target_user.id,
      email: target_user.email,
      phone_number: target_user.phone_number,
      first_name: target_user.first_name,
      last_name: target_user.last_name,
      full_name: target_user.full_name,
      profession: target_user.profession,
      business_name: target_user.business_name,
      business_address: target_user.business_address,
      business_image: target_user.business_image,
      skills: target_user.skills || [],
      has_onboarded: target_user.has_onboarded,
      created_at: target_user.created_at,
      updated_at: target_user.updated_at,
      custom_fields: serialized_custom_fields,
      total_folders: target_user.folders.count,
      total_gallery_images: target_user.galleries.count
    }
  end

  def authenticate_user!
    access_token = request.headers["Authorization"]&.split(" ")&.last

    if access_token.blank?
      render json: { error: "Authorization token required" }, status: :unauthorized
      return
    end

    result = AuthService.verify_jwt_token(access_token, "access")

    unless result[:success]
      status_code = result[:expired] ? :unauthorized : :unauthorized
      response_data = { success: false, messages: result[:messages] || [ "Authentication failed" ] }
      response_data[:expired] = true if result[:expired]
      render json: response_data, status: status_code
      return
    end

    @access_token = access_token
    @current_user = result[:user] # This is just like a middleware in nodejs so that the current_user can be accessed once initialized in the HTTP request
  end
end
