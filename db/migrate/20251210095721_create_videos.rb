class CreateVideos < ActiveRecord::Migration[8.0]
  def change
    create_table :videos do |t|
      t.string :title, null: false
      t.string :status, null: false
      t.string :hls_master_url

      t.timestamps
    end
  end
end
