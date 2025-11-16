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

    allowed_emails = [ "tzwizzycollections@gmail.com", "wisdomiyamu@gmail.com", "ibukunotusanya14@gmail.com", "fadaofficial01@gmail.com", "wisdom@hemline.studio", "adetunji@hemline.studio", "subomi@hemline.studio", "hello@hemline.studio", "adetunjidummy@gmail.com", "adetunjiadeyinka29@gmail.com" ]

    if email.present? && !allowed_emails.include?(email)
      render json: { errors: [ "Unauthorized email address" ] }, status: :unauthorized
      return
    end

    # Authenticate or create user
    result = AuthService.authenticate_user!(email)

    if !result[:success]
      render json: { errors: result[:messages] || [ "Authentication failed" ] }, status: :unprocessable_content
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
      # Set refresh token as httpOnly cookie
      set_refresh_token_cookie(result[:refresh_token])

      render json: {
        messages: result[:messages],
        success: true,
        data: {
          user: user_data(result[:user]),
          access_token: result[:access_token]
        }
      }
    else
      status_code = result[:expired] ? :unauthorized : :unprocessable_content
      response_data = { success: false, messages: result[:messages] || [ "Verification failed" ] }
      response_data[:expired] = true if result[:expired]
      render json: response_data, status: status_code
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
      # Set refresh token as httpOnly cookie
      set_refresh_token_cookie(result[:refresh_token])

      render json: {
        messages: result[:messages],
        success: true,
        data: {
          user: user_data(result[:user]),
          access_token: result[:access_token]
        }
      }
    else
      status_code = result[:expired] ? :unauthorized : :unprocessable_content
      response_data = { success: false, messages: result[:messages] || [ "Magic link verification failed" ] }
      response_data[:expired] = true if result[:expired]
      render json: response_data, status: status_code
    end
  end

  # GET /api/v1/auth/profile
  def profile
    render json: {
      message: "User data retrieved successfully",
      success: true,
      data: { user: user_data(), access_token: @access_token }
    }
  end

  # POST /api/v1/auth/refresh
  def refresh
    refresh_token = cookies[:refresh_token]

    if refresh_token.blank?
      render json: { errors: [ "Refresh token not found" ] }, status: :unauthorized
      return
    end

    result = AuthService.refresh_access_token(refresh_token)

    if result[:success]
      render json: {
        messages: result[:messages],
        success: true,
        data: {
          user: user_data(result[:user]),
          access_token: result[:access_token]
        }
      }
    else
      # Clear invalid refresh token cookie
      clear_refresh_token_cookie
      status_code = result[:expired] ? :unauthorized : :unauthorized
      response_data = { success: false, messages: result[:messages] || [ "Token refresh failed" ] }
      response_data[:expired] = true if result[:expired]
      render json: response_data, status: status_code
    end
  end

  # DELETE /api/v1/auth/logout
  def logout
    # Remove tokens server-side by deleting all token records for the user
    Token.revoke_user_tokens(@current_user)

    # Clear refresh token cookie
    clear_refresh_token_cookie

    render json: { message: "Logged out successfully" }
  end

  private

  def current_user
    @current_user
  end

  def set_refresh_token_cookie(refresh_token)
    response.headers["Set-Cookie"] = "refresh_token=#{refresh_token}; Path=/; Max-Age=2592000; HttpOnly; Secure; SameSite=Lax"

    cookies[:refresh_token] = {
      value: refresh_token,
      httponly: true,
      secure: true, # Only secure in production
      same_site: :lax,
      expires: 30.days.from_now
    }
  end

  def clear_refresh_token_cookie
    cookies.delete(:refresh_token, {
      httponly: true,
      secure: true,
      same_site: :lax
    })
  end
end
