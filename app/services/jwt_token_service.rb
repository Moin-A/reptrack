class JwtTokenService
  PAYLOAD_EXPIRATION = Time.now.to_i + 300;
  HMAC_SECRET = Rails.application.secret_key_base
  JWT_ALGORITHM = 'HS256'
  JWT_TYPE = 'JWT'

  def initialize(user)
    @user = user
  end

  def encode(payload)
    JWT.encode(payload,
        HMAC_SECRET,
        JWT_ALGORITHM,
        typ: JWT_TYPE
   )
  end


  def payload
    { user_id: @user.id,
      exp: PAYLOAD_EXPIRATION,
      sub: @user.email
     }
  end

  def decode(token)
    JWT.decode(token, HMAC_SECRET).first
  rescue JWT::DecodeError
    nil
  end
end
