require File.dirname(__FILE__) + '/spec_helper'

require 's3lurp'

ActionView::Base.send(:include, S3lurp::ViewHelpers)


describe S3lurp::ViewHelpers do
  before do
    ENV.clear
    S3lurp.reset_config
  end
  view = ActionView::Base.new

  it "should return a form tag with the proper action (using the bucket) and form options passed" do
    S3lurp.configure do |config|
    end
    form = view.s3_direct_form_tag({:key => '/files/s3lurp/lib/s3lurp.rb'})
  end

  it "should return a form with a minimum set of hidden fields for public buckets" do
    S3lurp.configure do |config|
      config.s3_key = nil
      config.s3_secret = nil
    end
    form = view.s3_direct_form_tag({:key => '/files/s3lurp/lib/s3lurp.rb'})
    (!!form.match(/<form /)).should be_true
    (!!form.match(/\<input.*?name="key".*?>/).to_s.match(/type="hidden"/)).should be_true
    (!!form.match(/\<input.*?name="file".*?>/).to_s.match(/type="file"/)).should be_true
  end

  it "should return a form with a policy and signature and my meta tags" do
    S3lurp.configure do |config|
      config.key = "/some/key.pl"
    end
    form = view.s3_direct_form_tag({
      :acl => 'public-read', 
      :amz_meta_tags => {
        :foo => 'bar',
        :object_id => 1234
    }})
    (!!form.match(/<form /)).should be_true
    (!!form.match(/\<input.*?name="key".*?>/).to_s.match(/value="\/some\/key\.pl"/)).should be_true
    (!!form.match(/\<input.*?name="file".*?>/).to_s.match(/type="file"/)).should be_true
    (!!form.match(/\<input.*?name="policy".*?>/).to_s.match(/type="hidden"/)).should be_true
    (!!form.match(/\<input.*?name="x-amz-meta-foo".*?>/).to_s.match(/value="bar"/)).should be_true
    (!!form.match(/\<input.*?name="x-amz-meta-object_id".*?>/).to_s.match(/value="1234"/)).should be_true
  end

  it 'should return valid json from the generate policy method and should have the keys I send it' do
    json = view.s3_generate_policy({:key => "/foo/bar/${filename}", :acl => 'public-read'}, 
                                   {:bucket => 'mybucket', 
                                    :expiration => "2013-03-14T21:16:51.000Z"})
    (!!(JSON.parse(json) rescue nil)).should be_true
    j = JSON.parse(json)
    j["expiration"].should == "2013-03-14T21:16:51.000Z"
    key_cond = j["conditions"].select{|a| a[1] == '$key'}.first
    key_cond[2].should == "/foo/bar"
  end
end

describe S3lurp do
  def random_string
    rand(36**8).to_s(36)
  end
  before do
    S3lurp.reset_config
    ENV.clear
    @bucket = random_string
    @key = random_string
    @secret = random_string
  end

  it 'should configure with options' do
    S3lurp.configure do |config|
      config.s3_bucket = @bucket
      config.s3_key = @key
      config.s3_secret = @secret
    end
    S3lurp.config.s3_bucket.should == @bucket
    S3lurp.config.s3_key.should == @key
    S3lurp.config.s3_secret.should == @secret
  end

  it 'should should always use ENV first for config' do
    ENV['S3_BUCKET'] = @bucket
    ENV['S3_KEY'] = @key
    ENV['S3_SECRET'] = @secret
    S3lurp.configure do |config|
      # nothing
    end
    S3lurp.config.s3_bucket.should == @bucket
    S3lurp.config.s3_key.should == @key
    S3lurp.config.s3_secret.should == @secret

  end

  it 'should configure from a yml file' do
    S3lurp.configure do |config|
      config.file = 's3.yml'
    end
    S3lurp.config.s3_bucket.should == 'yml_bucket'
    S3lurp.config.s3_key.should == 'yml_key'
    S3lurp.config.s3_secret.should == 'yml_secret'
  end
end

