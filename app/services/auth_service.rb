class AuthService
  def self.authenticate_user!(email)
    user = User.find_by(email: email.downcase) # Checks if a user exists with the provided email.

    # Create user if they don't exist; allow creation with email only
    if user.nil?
      # Store nil for names when not supplied to avoid saving placeholder data
      user = User.create!(
        email: email.downcase,
      )
    end

    # Generate auth code
    auth_code = user.generate_auth_code!

    {
      success: true,
      user: user,
      auth_code: auth_code,
      messages:  "Authentication code generated successfully"
    }
  end

  def self.verify_code(code)
    auth_code = AuthCode.valid_codes.find_by(code: code)

    return { success: false, message: "Invalid or expired code", errors: [ "Invalid or expired code" ] } unless auth_code

    # Mark code as used
    auth_code.use!

    # Generate access and refresh tokens
    tokens = generate_token_pair(auth_code.user)

    if auth_code.user.to_be_deleted
      {
        success: true,
        access_token: tokens[:access_token],
        to_be_deleted: true,
        date_requested_for_deletion: auth_code.user.date_requested_for_deletion,
        messages:  "Account scheduled for deletion"
      }
    else
      {
        success: true,
        user: auth_code.user,
        access_token: tokens[:access_token],
        refresh_token: tokens[:refresh_token],
        to_be_deleted: false,
        date_requested_for_deletion: nil,
        messages: "Authentication successful"
      }
    end
  end

  def self.verify_magic_link(token)
    auth_code = AuthCode.valid_codes.find_by(token: token)

    # Figure out how to approach the errors array issue from the render_error method in the base controller
    return { success: false, errors: [ "Invalid or expired magic link" ] } unless auth_code

    # Mark code as used
    auth_code.use!

    # Generate access and refresh tokens
    tokens = generate_token_pair(auth_code.user)

    if auth_code.user.to_be_deleted
      {
        success: true,
        access_token: tokens[:access_token],
        to_be_deleted: true,
        date_requested_for_deletion: auth_code.user.date_requested_for_deletion,
        messages: "Account scheduled for deletion"
      }
    else
      {
        success: true,
        user: auth_code.user,
        access_token: tokens[:access_token],
        refresh_token: tokens[:refresh_token],
        to_be_deleted: false,
        date_requested_for_deletion: nil,
        messages:  "Authentication successful"
      }
    end
  end

  def self.verify_jwt_token(token, expected_type = "access")
    return { success: false, errors: [ "Token is required" ] } if token.blank?

    payload = JwtService.decode(token)

    # Check if token is expired first
    if payload && payload[:exp] && Time.at(payload[:exp]) <= Time.current
      return { success: false, expired: true, errors:  [ "Token has expired" ] }
    end

    return { success: false, errors:  [ "Invalid token format" ]  } unless payload && JwtService.valid_payload?(payload)

    # Check if token type matches expected type
    token_type = JwtService.token_type(payload)
    return { success: false, errors: [ "Invalid token type" ] } unless token_type == expected_type

    user = User.find_by(id: payload[:user_id])

    return { success: false, errors:  [ "User not found" ]  } unless user

    # Ensure token exists in DB and is active
    token_record = Token.active.find_by(token: token, token_type: expected_type)
    return { success: false, errors:  [ "Token not found or expired" ]  } unless token_record && token_record.user_id == user.id

    {
      success: true,
      user: user,
      token_record: token_record,
      errors: [ "Token valid" ]
    }
  end

  def self.generate_tokens_for_user(user)
    generate_token_pair(user)
  end

  def self.refresh_access_token(refresh_token)
    # Verify refresh token
    result = verify_jwt_token(refresh_token, "refresh")
    return result unless result[:success]

    user = result[:user]

    # Clean up expired access tokens for this user
    Token.cleanup_expired_tokens(user)

    # Revoke old access tokens for this user
    Token.revoke_user_tokens(user, "access")

    # Generate new access token
    access_token = JwtService.encode_access_token({ user_id: user.id })
    Token.create!(
      user: user,
      token: access_token,
      token_type: "access",
      expires_at: JwtService::ACCESS_TOKEN_EXPIRATION.from_now
    )

    {
      success: true,
      user: user,
      access_token: access_token,
      messages: "Access token refreshed successfully"
    }
  end

  private

  def self.generate_token_pair(user)
    # Clean up expired tokens
    Token.cleanup_expired_tokens(user)

    # Revoke existing tokens for this user
    Token.revoke_user_tokens(user)

    # Generate new access token
    access_token = JwtService.encode_access_token({ user_id: user.id })
    Token.create!(
      user: user,
      token: access_token,
      token_type: "access",
      expires_at: JwtService::ACCESS_TOKEN_EXPIRATION.from_now
    )

    # Generate new refresh token
    refresh_token = JwtService.encode_refresh_token({ user_id: user.id })
    Token.create!(
      user: user,
      token: refresh_token,
      token_type: "refresh",
      expires_at: JwtService::REFRESH_TOKEN_EXPIRATION.from_now
    )

    {
      access_token: access_token,
      refresh_token: refresh_token
    }
  end
end
