require 'base64'
require 'openssl'
require 'digest/sha1'

module S3lurp
  module ViewHelpers
    HIDDEN_FIELD_MAP= {
      :key => 'key',
      :aws_access_key => 'AWSAccessKeyId',
      :acl => 'acl',
      :cache_control => 'Cache-Control',
      :content_type => 'Content-Type',
      :content_disposition => 'Content-Disposition',
      :content_encoding => 'Content-Encoding',
      :expires => 'Expires',
      :success_action_redirect => 'success_action_redirect',
      :success_action_status => 'success_action_status'
    }
    NON_FIELD_OPTIONS = %w( s3_bucket aws_secret_key
                           max_file_size min_file_size
                           amz_meta_tags minutes_valid
                           form_html_options file_field_tag_accept multiple_files form_fields_only no_file_input
                           submit_tag submit_tag_value submit_tag_options).map(&:to_sym)

    def s3_direct_form_fields(opt ={})
      s3_direct_form_tag(opt.merge!({:form_fields_only => true}))
    end


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
      if hidden_fields[:aws_access_key] # only generate security fields when necessary
        security_fields[:policy] = Base64.encode64(
          s3_generate_policy(
            hidden_fields.clone,
            { :meta_tags => amz_meta_tags,
              :s3_bucket => options[:s3_bucket],
              :expiration => expiration_date,
              :min_file_size => options[:min_file_size],
              :max_file_size => options[:max_file_size]
            }
        )).gsub(/\n/,'')
        security_fields[:signature] = Base64.encode64(
          OpenSSL::HMAC.digest(
            OpenSSL::Digest::Digest.new('sha1'),
            options[:aws_secret_key], security_fields[:policy])
        ).gsub(/\n/,'')
      end

      amz_meta_tags.merge! security_fields
      submit = s3_generate_submit_tag(options)
      file = s3_generate_file_field_tag(options)
      form_content = (
        hidden_fields.map{|k,v| hidden_field_tag(HIDDEN_FIELD_MAP[k],v, {:id => nil})}.join.html_safe +
        amz_meta_tags.map{|k,v| hidden_field_tag(k,v,{:id => nil})}.join.html_safe
      )
      form_content << field_set_tag(nil,:class=>"s3lurp_file") {file} unless options[:no_file_input]
      if options[:form_fields_only]
        form_content
      else
        form_tag("http://s3.amazonaws.com/#{options[:s3_bucket]}",  {:authenticity_token => false, :method => 'POST', :multipart => true}.merge(options[:form_html_options])) do
          ( form_content +
            field_set_tag(nil,:class=>"s3lurp_submit") {submit.html_safe} )
        end
      end
    end

    def s3_generate_policy(fields = {}, options = {})
      fields.delete(:aws_access_key)
      conditions = [
        { :bucket => options[:s3_bucket]},
        ['content-length-range', options[:min_file_size], options[:max_file_size]],
        ['starts-with', '$utf8', ""]
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
        options[:meta_tags].each do |k,v|
          conditions.push ["starts-with", "$#{k}", '']
        end
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

    def s3_generate_submit_tag(opt = {})
      opt[:submit_tag_options].update(:name => nil)
      if opt[:submit_tag]
        opt[:submit_tag]
      elsif opt[:submit_tag_value]
        submit_tag(opt[:submit_tag_value], opt[:submit_tag_options])
      else
        submit_tag("Upload", opt[:submit_tag_options])
      end
    end

    def s3_generate_file_field_tag(opt ={})
      opts = {:class => 's3lurp_file_tag'}
      opts.merge!({:accept => opt[:file_field_tag_accept]}) if opt[:file_field_tag_accept]
      opts.merge!({:multiple => true}) if opt[:multiple_files]
      file_field_tag('file', opts)
    end

  end
end

