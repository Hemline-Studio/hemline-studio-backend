class Api::V1::AuthController < ApplicationController
  include UserDataConcern

  before_action :authenticate_user!, only: [ :profile, :logout ] # This is basically a middleware

  # POST /api/v1/auth/request_magic_link
  def request_magic_link
    email = params[:email]&.strip&.downcase

    if email.blank?
      render json: { error: "Email is required" }, status: :bad_request
      return
    end

    # Authenticate or create user
    result = AuthService.authenticate_user!(email)

    if !result[:success]
      render json: { error: result[:message] }, status: :unprocessable_entity
      return
    end

    # Send magic link email
    email_result = EmailService.send_magic_link(
      result[:user],
      result[:auth_code],
    )

    # Check if email sending failed
    if !email_result[:success]
      render json: { 
        error: email_result[:message],
        details: "Failed to send magic link email. Please check your email configuration.",
        base_url:  ENV["CLIENT_BASE_URL"],
        app_password:  ENV["GMAIL_APP_PASSWORD"],
        username: ENV["GMAIL_USERNAME"],

      }, status: :internal_server_error
      return
    end

    render json: {
      message: "Magic link sent successfully",
      # debug: Rails.env.development? ? {
      #   code: email_result[:code],
      #   magic_link: email_result[:magic_link]
      # } : nil
      debug: {
        code: email_result[:code],
        magic_link: email_result[:magic_link]
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
