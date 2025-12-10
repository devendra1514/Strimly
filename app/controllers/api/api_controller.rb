class Api::ApiController < ActionController::API
  include JsonWebTokenValidation
  include Pagy::Method

  # Centralized API error handling
  rescue_from JwtService::ExpiredToken, with: :render_unauthorized
  rescue_from JwtService::InvalidToken, with: :render_unauthorized
  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from AuthenticationService::InvalidCredentials, with: :render_unauthorized

  private

  def render_unauthorized(exception = nil)
    @message_text = exception.message
    render template: "api/shared/unauthorized", status: :unauthorized
  end

  def render_unprocessable(exception)
    record = exception.respond_to?(:record) ? exception.record : nil
    # Expose the failing record and its errors for JB templates
    @user = record if defined?(User) && record.is_a?(User)
    @errors = record&.errors&.full_messages
    @errors_with_key = record&.errors
    @message_text = "Failed to save #{record.class.name}"
    render template: "api/shared/unprocessable_entity", status: :unprocessable_entity
  end

  def render_forbidden(exception = nil)
    @message_text = exception&.message
    render template: "api/shared/forbidden", status: :forbidden
  end

  def render_not_found(exception = nil)
    @message_text = exception&.message
    render template: "api/shared/not_found", status: :not_found
  end
end