class HlsCleanupJob < ApplicationJob
  queue_as :default

  def perform(video_id)
    storage = SupabaseStorage.new
    bucket = ENV.fetch("SUPABASE_BUCKET")
    prefix = "videos/#{video_id}/hls"

    storage.delete_prefixes(bucket, [prefix])
    Rails.logger.info "HLS cleanup done for video #{video_id}"
  rescue => e
    Rails.logger.error "HlsCleanupJob error: #{e.message}\n#{e.backtrace.first(10).join("\n")}"
  end
end
