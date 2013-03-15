require 'base64'
require 'openssl'
require 'digest/sha1'
require 'pry'

module S3lurp
  module ViewHelpers
    HIDDEN_FIELD_MAP= {
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
    NON_FIELD_OPTIONS = %w( s3_bucket s3_secret
                           max_file_size min_file_size
                           amz_meta_tags minutes_valid ).map(&:to_sym)

    def s3_direct_form_tag(opt = {})
      options = (NON_FIELD_OPTIONS + HIDDEN_FIELD_MAP.keys).each_with_object({}) do |i, h|
        h[i] = opt[i] || S3lurp.config.send(i)
      end

      # configurable fields the field map is formed as {:configuration_name => "input_field_name"}
      hidden_fields = HIDDEN_FIELD_MAP.each_with_object({}) do |(k,v), h|
        h[k] = options[k] unless options[k].nil? || options[k].blank?
      end

      amz_meta_tags = options[:amz_meta_tags].is_a?(Hash) ? s3_generate_amz_meta_tags(options[:amz_meta_tags]) : {}

      # generate an expiration date for the policy
      minutes = Integer(options[:minutes_valid]) rescue 360
      expiration_date = minutes.minutes.from_now.utc.strftime('%Y-%m-%dT%H:%M:%S.000Z')

      security_fields = {}
      if hidden_fields[:s3_key] # only generate security fields when necessary
        security_fields[:policy] = Base64.encode64(
          s3_generate_policy(
            hidden_fields,
            { :meta_tags => amz_meta_tags,
              :s3_bucket => options[:s3_bucket],
              :expiration => expiration_date,
              :min_file_size => options[:min_file_size] || 0,
              :max_file_size => options[:max_file_size] || 10.megabytes
            }
        )).gsub(/\n/,'')
        security_fields[:signature] = Base64.encode64(
          OpenSSL::HMAC.digest(
            OpenSSL::Digest::Digest.new('sha1'),
            options[:s3_secret], security_fields[:policy])
        ).gsub(/\n/,'')
      end

      amz_meta_tags.merge! security_fields
      form_tag("http://s3.amazonaws.com/#{options[:s3_bucket]}",  :authenticity_token => false, :class => "boing", :method => 'POST', :multipart => true) do
        (
        hidden_fields.map{|k,v| hidden_field_tag(HIDDEN_FIELD_MAP[k],v, {:id => nil})}.join.html_safe +
        amz_meta_tags.map{|k,v| hidden_field_tag(k,v,{:id => nil})}.join.html_safe +
        file_field_tag('file', :accept => "text/html")
        )
      end
    end

    def s3_generate_policy(fields = {}, options = {})
      fields.delete(:s3_key)
      conditions = [
        { :bucket => options[:s3_bucket]},
        ['content-length-range', options[:min_file_size], options[:max_file_size]]
      ]
      HIDDEN_FIELD_MAP.each do |field, field_name|
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

