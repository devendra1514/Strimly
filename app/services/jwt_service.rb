# frozen_string_literal: true

require "jwt"

class JwtService
  class InvalidToken < StandardError; end
  class ExpiredToken < StandardError; end

  class << self
    def encode(payload)
      payload = payload.dup
      payload[:exp] = (ENV["JWT_EXPIRATION_HOURS"].to_i || 24).hours.from_now.to_i unless payload[:exp].present?
      JWT.encode(payload, secret_key)
    end

    def decode(token)
      decoded = JWT.decode(
        token,
        secret_key,
        true,
        { algorithm: "HS256", verify_expiration: true }
      ).first

      HashWithIndifferentAccess.new(decoded)
    rescue JWT::ExpiredSignature
      raise ExpiredToken, "Token has expired"
    rescue JWT::DecodeError => e
      raise InvalidToken, "Invalid token"
    end

    private

    def secret_key
      Rails.application.secret_key_base
    end
  end
end
