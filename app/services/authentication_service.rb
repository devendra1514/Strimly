# frozen_string_literal: true

class AuthenticationService
  class InvalidCredentials < StandardError; end

  def initialize(user)
    @user = user
  end

  def authenticate_with_password(password)
    if @user.authenticate(password)
      @user.update!(jti: SecureRandom.uuid)
      JwtService.encode(user_id: @user.id, jti: @user.jti)
    else
      raise InvalidCredentials, "Invalid email or password"
    end
  end

  def refresh_jti
    @user.update!(jti: SecureRandom.uuid)
  end
end
