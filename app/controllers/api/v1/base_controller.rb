class Api::V1::BaseController < ApplicationController
  # Enable authentication for user-specific data access
  before_action :authenticate_user!

  protected

  def authenticate_user!
    authorization_header = request.headers["Authorization"]

    if authorization_header.blank?
      render_error([ "Authorization header required" ], "Authorization header required", :unauthorized)
      return
    end

    # Extract token from "Bearer <token>" format
    token_parts = authorization_header.split(" ")
    if token_parts.length != 2 || token_parts.first.downcase != "bearer"
      render_error([ "Invalid authorization header format. Expected: Bearer <token>" ], "Invalid authorization header format", :unauthorized)
      return
    end

    token = token_parts.last
    if token.blank?
      render_error([ "Authorization token required" ], "Authorization token required", :unauthorized)
      return
    end

    result = AuthService.verify_jwt_token(token)

    unless result[:success]
      render_error([ result[:message] ], result[:message], :unauthorized)
      return
    end

    @current_user = result[:user]
  end

  def current_user
    @current_user
  end

  def render_success(data = nil, message = "Operation completed successfully", status = :ok)
    response = {
      success: true,
      message: message
    }
    response[:data] = data if data

    render json: response, status: status
  end

  def render_error(errors, message = "Operation failed", status = :unprocessable_content)
    errors = [ errors ] unless errors.is_a?(Array)

    render json: {
      success: false,
      message: message,
      errors: errors
    }, status: status
  end

  def render_validation_errors(model, message = "Validation failed")
    render_error(model.errors.full_messages, message)
  end

  def render_not_found(message = "Resource not found")
    render_error([ message ], message, :not_found)
  end

  def paginate_collection(collection, per_page = 20)
    return { data: [], pagination: {} } if collection.blank?

    page = params[:page].presence || 1
    per_page = per_page.to_i
    per_page = 20 if per_page <= 0
    per_page = [ per_page, 100 ].min

    begin
      paginated_collection = collection.page(page).per(per_page)
    rescue => e
      Rails.logger.error("Pagination failed: #{e.message}")
      return { data: [], pagination: {} }
    end

    {
      data: paginated_collection,
      pagination: {
        current_page: paginated_collection.current_page,
        total_pages: paginated_collection.total_pages,
        total_count: paginated_collection.total_count,
        per_page: paginated_collection.limit_value
      }
    }
  end
end
