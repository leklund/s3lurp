require File.dirname(__FILE__) + '/spec_helper'

require 's3lurp'

ActionView::Base.send(:include, S3lurp::ViewHelpers)


describe S3lurp::ViewHelpers do
  before do
    ENV.clear
    S3lurp.reset_config
  end
  view = ActionView::Base.new

  it "should return a form with a minimum set of hidden fields for public buckets" do
    S3lurp.configure do |config|
      config.s3_access_key = nil
      config.s3_secret_key = nil
    end
    form = view.s3_direct_form_tag({:key => '/files/s3lurp/lib/s3lurp.rb'})
    (!!form.match(/<form.*?>/)).should be_true
    form.should include(%(name="key"), %(type="hidden"))
    form.should include(%(name="file"), %(type="file"))
  end

  it "should return a form with a policy and signature and my meta tags" do
    S3lurp.configure do |config|
      config.s3_bucket = "bucket_o_stuff"
      config.s3_access_key = 'oingoboingo'
      config.s3_secret_key = "qwerty5678_"
    end
    form = view.s3_direct_form_tag({
      :key => '/some/key.pl',
      :acl => 'public-read',
      :success_action_redirect => 'http://foobar.com/thanks',
      :success_action_status => 204,
      :content_disposition => "attachment",
      :min_file_size => 1024,
      :max_file_size => 6291456,
      :minutes_valid => 333,
      :amz_meta_tags => {
        :foo => "bar",
        :parent_id => 42
      },
      :form_html_options => {:class => "myclass", :id => "s3lurp_form"}
    })
    (!!form.match(/<form.*?>/)).should be_true
    form.should include(%(class="myclass"))
    form.should include(%(id="s3lurp_form"))
    form.should include(%(name="key"), %(value="/some/key.pl"))
    form.should include(%(name="AWSAccessKeyId"), %(value="oingoboingo"))
    form.should include(%(name="file"), %(type="file"))
    form.should include(%(name="policy"), %(type="hidden"))
    form.should include(%(name="x-amz-meta-foo"), %(value="bar"))
    form.should include(%(name="x-amz-meta-parent_id"), %(value="42"))
    form.should include(%(name="Content-Disposition"), %(type="hidden"), %(value="attachment"))

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

  it 'should return a submit tag or return the submit tag passed' do
    view.s3_generate_submit_tag({:submit_tag_value => "zootboot", :submit_tag_options => {}})\
      .should == %(<input type="submit" value="zootboot" />)
    view.s3_generate_submit_tag({:submit_tag_options => {:class => "noway"}})\
      .should == %(<input class="noway" type="submit" value="Upload" />)
    view.s3_generate_submit_tag({:submit_tag_value => "zootboot", :submit_tag_options => {:class => "noway"}})\
      .should == %(<input class="noway" type="submit" value="zootboot" />)
    view.s3_generate_submit_tag({:submit_tag => %(<input type=submit class="button" id="upload-button">), :submit_tag_options => {}})\
      .should == %(<input type=submit class="button" id="upload-button">)
    view.s3_generate_submit_tag({:submit_tag_options => {}})\
      .should == %(<input type="submit" value="Upload" />)
  end

  it 'should generate file field tag with and without accept=' do
    view.s3_generate_file_field_tag().should_not include("accept")
    view.s3_generate_file_field_tag({:file_field_tag_accept => "image/*"}).should include('accept="image/*"')
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
      config.s3_access_key = @key
      config.s3_secret_key = @secret
    end
    S3lurp.config.s3_bucket.should == @bucket
    S3lurp.config.s3_access_key.should == @key
    S3lurp.config.s3_secret_key.should == @secret
  end

  it 'should should always use ENV first for config' do
    ENV['S3_BUCKET'] = @bucket
    ENV['S3_ACCESS_KEY'] = @key
    ENV['S3_SECRET_KEY'] = @secret
    S3lurp.configure do |config|
      # nothing
    end
    S3lurp.config.s3_bucket.should == @bucket
    S3lurp.config.s3_access_key.should == @key
    S3lurp.config.s3_secret_key.should == @secret

  end

  it 'should configure from a yml file' do
    S3lurp.configure do |config|
      config.file = 's3.yml'
    end
    S3lurp.config.s3_bucket.should == 'yml_bucket'
    S3lurp.config.s3_access_key.should == 'yml_key'
    S3lurp.config.s3_secret_key.should == 'yml_secret'
  end
end

