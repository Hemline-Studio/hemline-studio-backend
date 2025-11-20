class Api::V1::AuthController < ApplicationController
  include UserDataConcern

  before_action :authenticate_user!, only: [ :profile, :logout, :request_delete_account, :cancel_delete_account, :delete_all_accounts ] # This is basically a middleware

  # POST /api/v1/auth/request_magic_link
  def request_magic_link
    email = params[:email]&.strip&.downcase

    if email.blank?
      render json: {
        success: false,
        message: "Validation failed",
        errors: [ "Email is required" ]
      }, status: :bad_request
      return
    end

    # allowed_emails = [ "tzwizzycollections@gmail.com", "wisdomiyamu@gmail.com", "ibukunotusanya14@gmail.com", "fadaofficial01@gmail.com", "wisdom@hemline.studio", "adetunji@hemline.studio", "subomi@hemline.studio", "hello@hemline.studio", "adetunjidummy@gmail.com", "adetunjiadeyinka29@gmail.com" ]

    # if email.present? && !allowed_emails.include?(email)
    #   render json: { errors: [ "Unauthorized email address" ] }, status: :unauthorized
    #   return
    # end

    # Authenticate or create user
    result = AuthService.authenticate_user!(email)

    if !result[:success]
      render json: {
        success: false,
        message: "Authentication failed",
        errors: result[:messages] || [ "Authentication failed" ]
      }, status: :unprocessable_content
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
      render json: {
        success: false,
        message: "Validation failed",
        errors: [ "Code is required" ]
      }, status: :bad_request
      return
    end

    result = AuthService.verify_code(code)

    if result[:success]
      # Set refresh token as httpOnly cookie
      set_refresh_token_cookie(result[:refresh_token]) if result[:refresh_token]

      data = {
        access_token: result[:access_token],
        to_be_deleted: result[:to_be_deleted],
        date_requested_for_deletion: result[:date_requested_for_deletion]
      }
      data[:user] = user_data(result[:user]) if result[:user]

      render json: {
        messages: result[:messages],
        success: true,
        data: data
      }
    else
      status_code = result[:expired] ? :unauthorized : :unprocessable_content
      response_data = {
        success: false,
        message: "Verification failed",
        errors: result[:messages] || [ "Verification failed" ]
      }
      response_data[:expired] = true if result[:expired]
      render json: response_data, status: status_code
    end
  end

  # GET /api/v1/auth/verify (magic link endpoint)
  def verify_magic_link
    token = params[:token]

    if token.blank?
      render json: {
        success: false,
        message: "Validation failed",
        errors: [ "Token is required" ]
      }, status: :bad_request
      return
    end

    result = AuthService.verify_magic_link(token)

    if result[:success]
      # Set refresh token as httpOnly cookie
      set_refresh_token_cookie(result[:refresh_token]) if result[:refresh_token]

      data = {
        access_token: result[:access_token],
        to_be_deleted: result[:to_be_deleted],
        date_requested_for_deletion: result[:date_requested_for_deletion]
      }
      data[:user] = user_data(result[:user]) if result[:user]

      render json: {
        messages: result[:messages],
        success: true,
        data: data
      }
    else
      status_code = result[:expired] ? :unauthorized : :unprocessable_content
      response_data = {
        success: false,
        message: "Magic link verification failed",
        errors: result[:messages] || [ "Magic link verification failed" ]
      }
      response_data[:expired] = true if result[:expired]
      render json: response_data, status: status_code
    end
  end

  # GET /api/v1/auth/profile
  def profile
    render json: {
      message: "User data retrieved successfully",
      success: true,
      data: {
        user: user_data(),
        access_token: @access_token,
        to_be_deleted: @current_user.to_be_deleted,
        date_requested_for_deletion: @current_user.date_requested_for_deletion
      }
    }
  end

  # POST /api/v1/auth/refresh
  def refresh
    refresh_token = cookies[:refresh_token]

    if refresh_token.blank?
      render json: {
        success: false,
        message: "Authentication failed",
        errors: [ "Refresh token not found" ]
      }, status: :unauthorized
      return
    end

    result = AuthService.refresh_access_token(refresh_token)

    if result[:success]
      render json: {
        messages: result[:messages],
        success: true,
        data: {
          user: user_data(result[:user]),
          access_token: result[:access_token],
          to_be_deleted: result[:to_be_deleted],
          date_requested_for_deletion: result[:date_requested_for_deletion]
        }
      }
    else
      # Clear invalid refresh token cookie
      clear_refresh_token_cookie
      status_code = result[:expired] ? :unauthorized : :unauthorized
      response_data = {
        success: false,
        message: "Token refresh failed",
        errors: result[:messages] || [ "Token refresh failed" ]
      }
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

  # POST /api/v1/auth/request_delete_account
  def request_delete_account
    @current_user.update!(
      to_be_deleted: true,
      date_requested_for_deletion: Time.current
    )

    # Send email notification
    EmailService.send_account_deletion_request(@current_user)

    # Revoke all tokens
    Token.revoke_user_tokens(@current_user)

    # Clear refresh token cookie
    clear_refresh_token_cookie

    render json: {
      success: true,
      message: "Account marked for deletion. It will be permanently deleted in 7 days."
    }
  end

  # POST /api/v1/auth/cancel_delete_account
  def cancel_delete_account
    @current_user.update!(
      to_be_deleted: false,
      date_requested_for_deletion: nil
    )

    tokens = AuthService.generate_tokens_for_user(@current_user)
    set_refresh_token_cookie(tokens[:refresh_token])

    render json: {
      success: true,
      message: "Account deletion request cancelled.",
      data: {
        user: user_data(@current_user),
        access_token: tokens[:access_token],
        to_be_deleted: false
      }
    }
  end

  # DELETE /api/v1/auth/delete_all_accounts
  def delete_all_accounts
    unless @current_user.email == "adetunji@hemline.studio"
      render json: {
        success: false,
        message: "Unauthorized",
        errors: [ "You are not authorized to perform this action" ]
      }, status: :forbidden
      return
    end

    # Find users marked for deletion more than 7 days ago
    users_to_delete = User.where(to_be_deleted: true)
                          .where("date_requested_for_deletion <= ?", 7.days.ago)

    count = users_to_delete.count
    users_to_delete.destroy_all

    render json: {
      success: true,
      message: "#{count} accounts deleted successfully."
    }
  end

  private

  def current_user
    @current_user
  end

  def set_refresh_token_cookie(refresh_token)
    response.set_header(
      "Set-Cookie",
      "refresh_token=#{refresh_token}; Path=/; Max-Age=2592000; HttpOnly; Secure; SameSite=Lax"
    )
    # response.headers["Set-Cookie"] = "refresh_token=#{refresh_token}; Path=/; Max-Age=2592000; HttpOnly; Secure; SameSite=Lax"

    cookies[:refresh_token] = {
      value: refresh_token,
      httponly: true,
      secure: true, # Only secure in production
      same_site: :lax,
      expires: 30.days.from_now
    }
  end

  def clear_refresh_token_cookie
    response.set_header(
      "Set-Cookie",
      "refresh_token=; Path=/; Max-Age=0; HttpOnly; Secure; SameSite=Lax"
    )

    cookies.delete(:refresh_token, {
      httponly: true,
      secure: true,
      same_site: :lax
    })
  end
end
