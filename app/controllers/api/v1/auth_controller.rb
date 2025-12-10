class Api::V1::AuthController < Api::V1::ApiController
  skip_before_action :authenticate_user!, only: [ :login_with_password ]
  before_action :find_user, only: [ :login_with_password ]

  def login_with_password
    @token = AuthenticationService.new(@user).authenticate_with_password(params[:password])
  end

  def logout
    AuthenticationService.new(current_user).refresh_jti
  end

  private

  def find_user
    @user = User.find_by(email: params[:email])
    raise ActiveRecord::RecordNotFound, "Account not found" unless @user
  end
end
