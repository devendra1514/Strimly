class Video < ApplicationRecord
  has_one_attached :file

  validates :title, presence: true

  enum :status, %i[processing processed]
end
