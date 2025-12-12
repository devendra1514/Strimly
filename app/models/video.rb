class Video < ApplicationRecord
  has_one_attached :file
  # has_many_attached :hls_files

  validates :title, presence: true

  after_destroy :enqueue_hls_cleanup

  def hls_url(resolution)
    base = ENV.fetch("SUPABASE_PUBLIC_URL") # New variable
    bucket = ENV.fetch("SUPABASE_BUCKET")
  
    "#{base}/storage/v1/object/public/#{bucket}/videos/#{id}/hls/#{resolution}/master.m3u8"
  end
  

  private

  def enqueue_hls_cleanup
    HlsCleanupJob.perform_later(id)
  end
end
