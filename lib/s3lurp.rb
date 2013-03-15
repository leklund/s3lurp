require 's3lurp/version'
require 's3lurp/view_helpers'
require 's3lurp/railtie' if defined? ::Rails::Railtie

module S3lurp
  class << self
    attr_accessor :config
  end

  def self.configure
    self.config ||= Configuration.new
    yield(config)
    if config.file
      loaded_conf = YAML.load_file(Rails.root.join("config", config.file).to_s)
      env_conf = loaded_conf[Rails.env] || loaded_conf
      %w( s3_bucket s3_access_key s3_secret_key ).each do |key|
        if !env_conf.key?(key)
          raise "Config file #{config.file} missing key #{key}"
        end
        config.send("#{key}=", env_conf[key])
      end
    end
  end

  def self.reset_config
    self.config = nil
  end

  class Configuration
    attr_accessor :s3_bucket, :s3_access_key, :s3_secret_key, :acl, :cache_control,
      :content_type, :content_disposition, :content_encoding, :expires,
      :success_action_redirect, :success_action_status,
      :min_file_size, :max_file_size,
      :amz_meta_tags, :minutes_valid,
      :file, :key

    def initialize
      @s3_bucket = ENV['S3_BUCKET'] || "S3_BUCKET"
      @s3_access_key = ENV['S3_ACCESS_KEY'] || "S3_KEY"
      @s3_secret_key = ENV['S3_SECRET_KEY'] || "S3_SECRET"
    end

  end

end
