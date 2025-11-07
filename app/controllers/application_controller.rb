class ApplicationController < ActionController::API
  before_action :set_cors_headers

  rescue_from ActionDispatch::Http::Parameters::ParseError, with: :handle_parse_error

  def cors_preflight
    head :ok
  end

  def not_found
    render json: {
      status: 404,
      error: "Not Found",
      message: "This endpoint does not exist, I don't know what you are looking for 🙄"
    }, status: :not_found
  end

  private

  def set_cors_headers
    if Rails.env.production?
      allowed_origins = [
        "https://hemline-frontend.vercel.app",
        "https://hemline.studio",
        "https://www.hemline.studio"
      ]
      
      origin = request.headers["Origin"]
      
      if allowed_origins.include?(origin) || origin&.match?(/https:\/\/.*\.vercel\.app$/)
        response.headers["Access-Control-Allow-Origin"] = origin
        response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD"
        response.headers["Access-Control-Allow-Headers"] = "Origin, Content-Type, Accept, Authorization, X-Requested-With"
        response.headers["Access-Control-Allow-Credentials"] = "true"
        response.headers["Access-Control-Expose-Headers"] = "Authorization"
        response.headers["Access-Control-Max-Age"] = "600"
      end
    else
      # In development, allow all localhost origins
      origin = request.headers["Origin"]
      if origin&.match?(/http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/)
        response.headers["Access-Control-Allow-Origin"] = origin
        response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD"
        response.headers["Access-Control-Allow-Headers"] = "Origin, Content-Type, Accept, Authorization, X-Requested-With"
        response.headers["Access-Control-Allow-Credentials"] = "true"
        response.headers["Access-Control-Expose-Headers"] = "Authorization"
      end
    end
  end

  def handle_parse_error(exception)
    render json: { error: "Malformed request body" }, status: :bad_request
  end
end
