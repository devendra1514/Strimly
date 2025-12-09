require 'database_cleaner/active_record'

RSpec.configure do |config|
  config.before(:suite) do
    ActiveRecord::Base.connection.execute(<<~SQL)
      INSERT INTO spatial_ref_sys (srid, auth_name, auth_srid, srtext, proj4text)
      SELECT 4326, 'EPSG', 4326,
        'GEOGCS["WGS 84",DATUM["WGS_1984",SPHEROID["WGS 84",6378137,298.257223563]],' ||
        'PRIMEM["Greenwich",0],UNIT["degree",0.0174532925199433]]',
        '+proj=longlat +datum=WGS84 +no_defs'
      WHERE NOT EXISTS (SELECT 1 FROM spatial_ref_sys WHERE srid = 4326);
    SQL
    DatabaseCleaner.clean_with(:truncation, except: %w[spatial_ref_sys geometry_columns geography_columns])
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation, { except: %w[spatial_ref_sys geometry_columns geography_columns] }
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
