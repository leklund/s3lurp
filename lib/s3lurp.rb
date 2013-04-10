require 's3lurp/version'
require 's3lurp/view_helpers'
require 's3lurp/railtie' if defined? ::Rails::Railtie

module S3lurp
 VALID_CONFIG_KEYS = [
      :s3_bucket, :aws_access_key, :aws_secret_key, :acl, :cache_control,
      :content_type, :content_disposition, :content_encoding, :expires,
      :success_action_redirect, :success_action_status,
      :min_file_size, :max_file_size,
      :amz_meta_tags, :minutes_valid,
      :form_html_options, :file_field_tag_accept,
      :submit_tag, :submit_tag_value, :submit_tag_options,
      :file, :key].freeze
  class << self
    attr_accessor :config
  end

  def self.configure
    self.config ||= Configuration.new
    yield(config)
    if config.file
      loaded_conf = YAML.load_file(Rails.root.join("config", config.file).to_s)
      env_conf = loaded_conf[Rails.env] || loaded_conf
      VALID_CONFIG_KEYS.each do |key|
        config.send("#{key.to_s}=", env_conf[key.to_s])
      end
    end
  end

  def self.reset_config
    self.config = nil
  end

  class Configuration
    attr_accessor *VALID_CONFIG_KEYS

    def initialize
      @s3_bucket = ENV['S3_BUCKET'] || "S3_BUCKET"
      @aws_access_key = ENV['AWS_ACCESS_KEY'] || "AWS_KEY"
      @aws_secret_key = ENV['AWS_SECRET_KEY'] || "AWS_SECRET"
      @min_file_size = 0
      @max_file_size = 10485760
      @minutes_valid = 360
      @form_html_options = {}
      @submit_tag_options = {}
    end

  end

end
