require 'base64'
require 'openssl'
require 'digest/sha1'
require 'pry'

module S3lurp
  module ViewHelpers
    FIELD_MAP= {
      :key => 'key',
      :s3_key => 'AWSAccessKeyId',
      :acl => 'acl',
      :cache_control => 'Cache-Control',
      :content_type => 'Content-Type',
      :content_disposition => 'Content-Disposition',
      :content_encoding => 'Content-Encoding',
      :expires => 'Expires',
      :success_action_redirect => 'success_action_redirect',
      :success_action_status => 'success_action_status'
    }
    def s3_direct_form_tag(options = {})
      bucket = options[:s3_bucket] || S3lurp.config.s3_bucket
      secret = options[:s3_secret] || S3lurp.config.s3_secret
      minutes = Integer(options[:minutes_valid]) rescue 360
      expiration_date = minutes.minutes.from_now.utc.strftime('%Y-%m-%dT%H:%M:%S.000Z')

      # configurable fields the field map is formed as {:configuration_name => "input_field_name"}
      hidden_fields = {}
      FIELD_MAP.each do |k,v|
        hidden_fields[k] = options[k] || S3lurp.config.send(k.to_s.underscore.to_sym)
      end
      hidden_fields.delete_if{|k,v| v.nil? || v.empty?}

      amz_meta_tags = options[:amz_meta_tags].is_a?(Hash) ? s3_generate_amz_meta_tags(options[:amz_meta_tags]) : {}

      security_fields = {}
      if hidden_fields[:s3_key] # only generate security fields when necessary
        security_fields[:policy] = Base64.encode64(s3_generate_policy(hidden_fields, {:meta_tags => amz_meta_tags, :bucket => bucket, :expiration => expiration_date})).gsub(/\n/,'') if hidden_fields[:s3_key]
        security_fields[:signature] = Base64.encode64(
          OpenSSL::HMAC.digest(
            OpenSSL::Digest::Digest.new('sha1'),
            secret, security_fields[:policy])
        ).gsub(/\n/,"")
      end
      amz_meta_tags.merge! security_fields
      form_tag("http://s3.amazonaws.com/#{bucket}",  :authenticity_token => false, :class => "boing", :method => 'POST', :multipart => true) do
        (
        hidden_fields.map{|k,v| hidden_field_tag(FIELD_MAP[k],v, {:id => nil})}.join.html_safe +
        amz_meta_tags.map{|k,v| hidden_field_tag(k,v,{:id => nil})}.join.html_safe +
        file_field_tag('file', :accept => "text/html")
        )
      end
    end

    def s3_generate_policy(fields = {}, options = {})
      fields.delete(:s3_key)
      conditions = [{ :bucket => options[:bucket]}]
      FIELD_MAP.each do |field, field_name|
        next unless fields[field]
        case field
        when :key
          key = fields[field].gsub(/\/?\$\{filename\}\/?/,'')
          conditions.push ["starts-with", "$key", key]
        else
          conditions.push ({ field_name => fields[field] })
        end
      end
      if options[:meta_tags]
        conditions = conditions + options[:meta_tags].map{|k,v| {k => v}}
      end
      policy = {
        "expiration" => options[:expiration],
        "conditions" => conditions
      }.to_json
    end

    def s3_generate_amz_meta_tags(meta = {})
      meta.each_with_object({}) do |(k,v), hash|
        hash[%(x-amz-meta-#{k})] = v
      end
    end
  end
end

