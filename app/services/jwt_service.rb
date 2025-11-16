class JwtService
  SECRET_KEY = Rails.application.credentials.secret_key_base || "fallback_secret_key"

  # Token expiration times
  ACCESS_TOKEN_EXPIRATION = 10.seconds
  REFRESH_TOKEN_EXPIRATION = 30.days

  def self.encode(payload, exp = ACCESS_TOKEN_EXPIRATION.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end

  def self.encode_access_token(payload)
    payload[:token_type] = "access"
    encode(payload, ACCESS_TOKEN_EXPIRATION.from_now)
  end

  def self.encode_refresh_token(payload)
    payload[:token_type] = "refresh"
    encode(payload, REFRESH_TOKEN_EXPIRATION.from_now)
  end

  def self.decode(token)
    return nil if token.blank?

    begin
      body = JWT.decode(token, SECRET_KEY)[0]
      HashWithIndifferentAccess.new(body)
    rescue JWT::DecodeError, JWT::ExpiredSignature, JWT::InvalidSignature => e
      Rails.logger.warn "JWT decode error: #{e.message}"
      nil
    rescue => e
      Rails.logger.error "Unexpected JWT decode error: #{e.message}"
      nil
    end
  end

  def self.valid_payload?(payload)
    payload && payload[:exp] && Time.at(payload[:exp]) > Time.current
  end

  def self.token_type(payload)
    payload[:token_type] if payload
  end
end
