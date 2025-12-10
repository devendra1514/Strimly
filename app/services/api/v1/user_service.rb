class Api::V1::UserService
  def self.create(params)
    user = User.new(params)
    user.save!
    user
  end
end