require "open3"
require "fileutils"
require "shellwords"

class VideoProcessingJob < ApplicationJob
  queue_as :default
  retry_on StandardError, attempts: 3

  RESOLUTIONS = {
    "0" => "1080",
    "1" => "720",
    "2" => "480"
  }.freeze

  def perform(video_id)
    video = Video.find(video_id)
    video.update!(status: :processing)

    Dir.mktmpdir("video_proc_#{video_id}") do |work_dir|
      work_dir = Pathname.new(work_dir)
      input_ext = File.extname(video.file.filename.to_s)
      source_path = work_dir.join("source#{input_ext.presence || '.mp4'}")

      # Download original file
      File.open(source_path, "wb") { |f| f.write(video.file.download) }

      out_dir = work_dir.join("out")
      FileUtils.mkdir_p(out_dir)

      # Run ffmpeg HLS
      ffmpeg_cmd = build_ffmpeg_cmd(source_path.to_s, out_dir.to_s)
      Rails.logger.info("VideoProcessingJob: running ffmpeg: #{ffmpeg_cmd}")

      stdout_str, stderr_str, status = Open3.capture3(ffmpeg_cmd)

      unless status.success?
        Rails.logger.error("FFmpeg failed: #{stderr_str}")
        video.update!(status: :failed)
        return
      end

      # Rename numeric folders to resolution folders
      RESOLUTIONS.each do |num, name|
        src = out_dir.join(num)
        next unless src.exist?

        dest = out_dir.join(name)
        FileUtils.mv(src, dest)
      end

      # Upload generated HLS structure
      storage = SupabaseStorage.new
      bucket = ENV.fetch("SUPABASE_BUCKET")
      base_prefix = "videos/#{video.id}/hls"

      Dir.glob("#{out_dir}/**/*").sort.each do |file|
        next if File.directory?(file)

        relative = Pathname.new(file).relative_path_from(out_dir).to_s
        key = "#{base_prefix}/#{relative}"

        content_type = content_type_for(file)
        Rails.logger.debug("Uploading #{file} -> #{key} (#{content_type})")

        storage.upload(
          bucket,
          key,
          File.binread(file),
          content_type: content_type
        )
      end

      # Set public master URL
      master_path = "#{base_prefix}/master.m3u8"
      public_master = storage.public_url(bucket, master_path)

      video.update!(hls_master_url: public_master, status: :ready)
    end

  rescue => e
    Rails.logger.error("VideoProcessingJob error: #{e.message}\n#{e.backtrace.first(10).join("\n")}")
    video.update!(status: :failed) if defined?(video) && video.present?
  end

  private

  def build_ffmpeg_cmd(src, out)
    src_esc = Shellwords.escape(src)
    out_esc = Shellwords.escape(out)

    <<~CMD.squish
      ffmpeg -y -hide_banner -loglevel error -i #{src_esc} \
        -filter_complex "[0:v]split=3[v1080][v720][v480]; \
          [v1080]scale=1920:1080:force_original_aspect_ratio=decrease:force_divisible_by=2[v1080out]; \
          [v720]scale=1280:720:force_original_aspect_ratio=decrease:force_divisible_by=2[v720out]; \
          [v480]scale=854:480:force_original_aspect_ratio=decrease:force_divisible_by=2[v480out]" \
        \
        -map [v1080out] -c:v:0 libx264 -b:v:0 1500k -maxrate:v:0 1650k -bufsize:v:0 3000k -preset veryfast -g 48 -sc_threshold 0 \
        -map [v720out]  -c:v:1 libx264 -b:v:1 900k  -maxrate:v:1 1000k -bufsize:v:1 2000k -preset veryfast -g 48 -sc_threshold 0 \
        -map [v480out]  -c:v:2 libx264 -b:v:2 500k  -maxrate:v:2 600k  -bufsize:v:2 1200k -preset veryfast -g 48 -sc_threshold 0 \
        \
        -map a:0 -c:a:0 aac -b:a:0 128k \
        -map a:0 -c:a:1 aac -b:a:1 128k \
        -map a:0 -c:a:2 aac -b:a:2 128k \
        \
        -f hls -hls_time 10 -hls_playlist_type vod \
        -master_pl_name master.m3u8 \
        -hls_segment_filename "#{out_esc}/%v/segment_%03d.ts" \
        -var_stream_map "v:0,a:0 v:1,a:1 v:2,a:2" \
        #{out_esc}/%v/master.m3u8
    CMD
  end

  def content_type_for(path)
    ext = File.extname(path)
    return "application/vnd.apple.mpegurl" if ext == ".m3u8"
    return "video/mp2t" if ext == ".ts"
    "application/octet-stream"
  end
end
