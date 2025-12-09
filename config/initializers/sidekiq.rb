Sidekiq.configure_server do |config|
  config.redis = { url: ENV["REDIS_URL"] }
  config.on(:startup) do
    schedule_file = Rails.root.join("config/sidekiq_scheduler.yml")
    if File.exist?(schedule_file)
      Sidekiq.schedule = YAML.load_file(schedule_file)
      SidekiqScheduler::Scheduler.instance.reload_schedule!
    end
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV["REDIS_URL"] }
end
