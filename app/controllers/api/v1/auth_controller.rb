class Api::V1::AuthController < ApplicationController
  include UserDataConcern

  before_action :authenticate_user!, only: [ :profile, :logout ] # This is basically a middleware

  # POST /api/v1/auth/request_magic_link
  def request_magic_link
    email = params[:email]&.strip&.downcase

    if email.blank?
      render json: { errors: [ "Email is required" ] }, status: :bad_request
      return
    end

    allowed_emails = [ "wisdomiyamu@gmail.com", "ibukunotusanya14@gmail.com", "fadaofficial01@gmail.com", "wisdom@hemline.studio", "adetunji@hemline.studio", "subomi@hemline.studio", "hello@hemline.studio", "adetunjidummy@gmail.com", "adetunjiadeyinka29@gmail.com" ]

    if email.present? && !allowed_emails.include?(email)
      render json: { errors: [ "Unauthorized email address" ] }, status: :unauthorized
      return
    end

    # Authenticate or create user
    result = AuthService.authenticate_user!(email)

    if !result[:success]
      render json: { errors: [ result[:message] ] }, status: :unprocessable_entity
      return
    end

    # Send magic link email
    email_result = EmailService.send_magic_link(
      result[:user],
      result[:auth_code],
      ENV["CLIENT_BASE_URL"]
    )

    if !email_result[:success]
      Rails.logger.error "Failed to send magic link email: #{email_result[:message]}"
      # Continue even if email fails - user can still use the code
    end

    render json: {
      message: "Magic link sent successfully",
      debug: {
        code: result[:auth_code].code,
        magic_link: result[:auth_code].magic_link(ENV["CLIENT_BASE_URL"])
      }
    }
  end

  # POST /api/v1/auth/verify_code
  def verify_code
    code = params[:code]&.strip

    if code.blank?
      render json: { error: "Code is required" }, status: :bad_request
      return
    end

    result = AuthService.verify_code(code)

    if result[:success]

      render json: {
        message: result[:message],
        success: true,
        data: { user: user_data(result[:user]), token: result[:token] }
      }
    else
      render json: { error: result[:message] }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/auth/verify (magic link endpoint)
  def verify_magic_link
    token = params[:token]

    if token.blank?
      render json: { error: "Token is required" }, status: :bad_request
      return
    end

    result = AuthService.verify_magic_link(token)

    if result[:success]

      render json: {
        message: result[:message],
        success: true,
        data: { user: user_data(result[:user]), token: result[:token] }
      }
    else
      render json: { error: result[:message] }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/auth/profile
  def profile
    render json: {
      message: "User data retrieved successfully",
      success: true,
      data: { user: user_data(), token: @token }
    }
  end

  # DELETE /api/v1/auth/logout
  def logout
    # Remove token server-side by deleting the token record
    token = request.headers["Authorization"]&.split(" ")&.last
    if token.present?
      token_record = Token.find_by(token: token)
      token_record&.destroy
    end

    render json: { message: "Logged out successfully" }
  end

  private

  def current_user
    @current_user
  end
end
