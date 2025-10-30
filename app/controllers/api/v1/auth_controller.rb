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

    # Queue magic link email to be sent asynchronously
    # User gets immediate response while email sends in background

    render json: {
      message: "Magic link sent successfully",
      debug: {
        code: result[:auth_code].code,
        magic_link: result[:auth_code].magic_link(ENV["CLIENT_BASE_URL"])
      }
    }

    # Temporarily use a thread to send email in background
    Thread.new do
      user = User.find(result[:user].id)
      auth_code = AuthCode.find(result[:auth_code].id)
      EmailService.send_magic_link(user, auth_code)
      Rails.logger.info "Successfully sent #{params[:email]&.strip&.downcase} email"
    end
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
