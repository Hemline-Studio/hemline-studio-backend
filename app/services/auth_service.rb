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
      message: "Authentication code generated successfully"
    }
  end

  def self.verify_code(code)
    auth_code = AuthCode.valid_codes.find_by(code: code)

    return { success: false, message: "Invalid or expired code" } unless auth_code

    # Mark code as used
    auth_code.use!

  # Generate JWT token and persist it
  token = JwtService.encode({ user_id: auth_code.user.id })
  Token.create!(user: auth_code.user, token: token, expires_at: 24.hours.from_now)

    {
      success: true,
      user: auth_code.user,
      token: token,
      message: "Authentication successful"
    }
  end

  def self.verify_magic_link(token)
    auth_code = AuthCode.valid_codes.find_by(token: token)

    # Figure out how to approach the errors array issue from the render_error method in the base controller
    return { success: false, message: "Invalid or expired magic link" } unless auth_code

    # Mark code as used
    auth_code.use!

    # Generate JWT token and persist it
    jwt_token = JwtService.encode({ user_id: auth_code.user.id })
    Token.create!(user: auth_code.user, token: jwt_token, expires_at: 24.hours.from_now)

    {
      success: true,
      user: auth_code.user,
      token: jwt_token,
      message: "Authentication successful"
    }
  end

  def self.verify_jwt_token(token)
    return { success: false, message: "Token is required" } if token.blank?

    payload = JwtService.decode(token)

    return { success: false, message: "Invalid token format" } unless payload && JwtService.valid_payload?(payload)

    user = User.find_by(id: payload[:user_id])

    return { success: false, message: "User not found" } unless user

    # Ensure token exists in DB and is active
    token_record = Token.active.find_by(token: token)
    return { success: false, message: "Token not found or expired" } unless token_record && token_record.user_id == user.id

    {
      success: true,
      user: user,
      message: "Token valid"
    }
  end
end
