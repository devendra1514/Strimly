require "aws-sdk-s3"

class SupabaseStorage
  def initialize
    @client = Aws::S3::Client.new(
      access_key_id:     ENV.fetch("SUPABASE_S3_ACCESS_KEY"),
      secret_access_key: ENV.fetch("SUPABASE_S3_SECRET_KEY"),
      region:            ENV.fetch("SUPABASE_S3_REGION", "auto"),
      endpoint:          ENV.fetch("SUPABASE_S3_ENDPOINT"),
      force_path_style:  true
    )
  end

  # Upload to S3 bucket/path
  def upload(bucket, path, file_body, content_type: "application/octet-stream")
    @client.put_object(
      bucket: bucket,
      key: path,
      body: file_body,
      content_type: content_type
    )
  end

  # Delete multiple object prefixes
  def delete_prefixes(bucket, prefixes)
    objects = prefixes.flat_map do |prefix|
      list = @client.list_objects_v2(bucket: bucket, prefix: prefix)
      list.contents.map { |c| { key: c.key } }
    end

    return if objects.empty?

    @client.delete_objects(
      bucket: bucket,
      delete: { objects: objects }
    )
  end

  # Public URL (STATIC URL, not signed)
  def public_url(bucket, path)
    "#{ENV.fetch('SUPABASE_S3_ENDPOINT')}/#{bucket}/#{path}"
  end
end
