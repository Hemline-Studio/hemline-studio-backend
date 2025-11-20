class ApplicationController < ActionController::API
  include ActionController::Cookies

  rescue_from ActionDispatch::Http::Parameters::ParseError, with: :handle_parse_error

  def not_found
    render json: {
      success: false,
      message: "This endpoint does not exist, I don't know what you are looking for 🙄",
      errors: ["Not Found"]
    }, status: :not_found
  end

  private

  def handle_parse_error(exception)
    render json: {
      success: false,
      message: "Malformed request body",
      errors: ["Invalid JSON format"]
    }, status: :bad_request
  end
end
