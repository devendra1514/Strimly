class Api::V1::VideosController < Api::V1::ApiController
  skip_before_action :authenticate_user!, only: [:generate_presigned_url, :attach]

  def generate_presigned_url
    blob = ActiveStorage::Blob.create_before_direct_upload!(
      filename: params[:filename],
      content_type: params[:content_type],
      byte_size: params[:byte_size],
      checksum: params[:checksum]
    )

    url = blob.service_url_for_direct_upload
    headers = blob.service_headers_for_direct_upload

    render json: {
      direct_upload: {
        url: url,
        headers: headers
      },
      blob_signed_id: blob.signed_id
    }
  end

  def attach
    blob = ActiveStorage::Blob.find_signed(params[:blob_signed_id])
    video = Video.new(title: blob.filename, status: :processing)
    video.file.attach(blob)
    video.save!
    render json: video
  end
end