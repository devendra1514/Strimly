class Api::V1::UsersController < Api::V1::ApiController
  skip_before_action :authenticate_user!, only: :create

  def create
    Api::V1::UserService.create(params)
  end
end