class Api::ApiController < ActionController::API
  include ActionController::MimeResponds

  before_action :set_default_format
  respond_to :json

  include JsonWebTokenValidation
  include Pagy::Method

  # Centralized API error handling
  rescue_from JwtService::ExpiredToken, with: :render_unauthorized
  rescue_from JwtService::InvalidToken, with: :render_unauthorized

  private

  def set_default_format
    request.format = :json
  end

  def render_unauthorized(exception = nil)
    render json: { message: exception.message }, status: :unauthorized
  end
end