class Api::V1::UsersController < Api::V1::ApiController
  skip_before_action :authenticate_user!, only: :create

  def create
    UserService.create(user_params)
  end

  private
    def user_params
      params.permit(:email, :password, :password_confirmation)
    end
end