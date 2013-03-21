require 'aws-sdk'

module S3lurp
  class Magneto
    attr_reader :bucket
    attr_accessor :s3_original_file, :local_tmp
    @queue = :s3lurp

    def initialize(bucket, *aws_config)
      # aws_config = {:access_key_id => 'YOUR_ACCESS_KEY_ID',
      # :secret_access_key => 'SECRET' }
      # optional as config may be set with AWS::S3.config in an initializer
      aws_config ||= {}
      s3 = AWS::S3.new(aws_config)
      @bucket = s3.buckets[bucket]
    end

    class << self
      def perform(klass, bucket, s3_key, options={})
        # DO SOMETHING
        magnet = S3lurp::Magnet.new(bucket)
        object = magnet.get_new_object(klass)
        parent = magnet.get_parent_object(options) if options[:parent_klass] && options[:parent_id]

      end
    end

    def get_new_object(klass)
      klass.camelize.constantize.new
    end

    def get_parent_object(options={})
      options[:parent_klass].camelize.constantize.find(options[:parent_id])
    end

  end
end
