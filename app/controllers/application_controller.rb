class ApplicationController < ActionController::API
  rescue_from ActionDispatch::Http::Parameters::ParseError, with: :handle_parse_error

  def not_found
    render json: {
      status: 404,
      error: "Not Found",
      message: "This endpoint does not exist, I don't know what you are looking for 🙄"
    }, status: :not_found
  end

  private

  def handle_parse_error(exception)
    render json: { error: "Malformed request body" }, status: :bad_request
  end
end
