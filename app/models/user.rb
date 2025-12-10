class User < ApplicationRecord

  has_secure_password

  # Callbacks
  before_validation :generate_username, on: :create, if: -> { username.blank? }
  before_create {
    self.jti = SecureRandom.uuid
  }

  validates :username,
              presence: true,
              uniqueness: true,
              format: { with: /\A[a-z0-9_.]+\z/, message: "can only contain lowercase letters, numbers, underscores, and dots" },
              length: { minimum: 3, maximum: 30 }

  validates :email,
              presence: true,
              uniqueness: true,
              format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :password,
              presence: true,
              confirmation: true,
              format: {
                with: /\A(?=.*[0-9])(?=.*[a-z])(?=.*[A-Z]).{6,}\z/,
                message: "must contain at least one lowercase, one uppercase, one digit, and be 6+ characters"
              },
              on: :create

  validates :password,
              confirmation: true,
              format: {
                with: /\A(?=.*[0-9])(?=.*[a-z])(?=.*[A-Z]).{6,}\z/,
                message: "must contain at least one lowercase, one uppercase, one digit, and be 6+ characters"
              },
              if: -> { password.present? && !new_record? }

  validates :password_confirmation, presence: true, if: -> { password.present? }

  private

    def generate_username
      self.username = SecureRandom.hex(10)
    end
end
