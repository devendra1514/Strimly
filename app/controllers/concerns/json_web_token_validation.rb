module JsonWebTokenValidation
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  def authenticate_user!
    token = extract_token

    unless token.present?
      raise JwtService::InvalidToken, "Missing authentication token"
    end

    decode_hash = JwtService.decode(token)

    @current_user = User.find_by(id: decode_hash[:user_id], jti: decode_hash[:jti])

    unless @current_user
      raise JwtService::InvalidToken, "Account not found"
    end
  end

  def current_user
    @current_user
  end

  private

  def extract_token
    # Only accept Authorization header with Bearer scheme
    auth_header = request.headers["Authorization"]
    return unless auth_header

    if auth_header.start_with?("Bearer ")
      auth_header.split(" ", 2).last
    end
  end
end
