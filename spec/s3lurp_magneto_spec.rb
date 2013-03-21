require File.dirname(__FILE__) + '/spec_helper'

require 's3lurp'

describe S3lurp::Magneto do
  before do
    @magnet = S3lurp::Magneto.new($bucket)
  end
  it "should initialize with an s3 bucket instance" do
    @magnet.bucket.class.should == AWS::S3::Bucket
    @magnet.bucket.exists?.should be_true
  end
  
  it "should respond to get_new_object and return an object" do
    @magnet.should respond_to(:get_new_object).with(1).argument
    object = @magnet.get_new_object('klass')
    object.class.should == Klass
  end

  it "should respond to get_parent_object and return it" do
    @magnet.should respond_to(:get_parent_object).with(1).argument
    parent = @magnet.get_parent_object({:parent_klass => 'parent', :parent_id => 1})
    parent.class.should == Parent
    parent.id.should == 1
  end

end
