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
      first_name: target_user.first_name,
      last_name: target_user.last_name,
      full_name: target_user.full_name,
      profession: target_user.profession,
      business_name: target_user.business_name,
      business_address: target_user.business_address,
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
    token = request.headers["Authorization"]&.split(" ")&.last

    if token.blank?
      render json: { error: "Authorization token required" }, status: :unauthorized
      return
    end

    result = AuthService.verify_jwt_token(token)

    unless result[:success]
      render json: { error: result[:message] }, status: :unauthorized
      return
    end

    @token = token
    @current_user = result[:user] # This is jsut like a middleware in nodejs so that the current_user can be accessed once initialized in the HTTP request
  end
end
