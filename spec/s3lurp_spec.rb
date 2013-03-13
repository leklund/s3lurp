require File.dirname(__FILE__) + '/spec_helper'

require 's3lurp'

ActionView::Base.send(:include, S3lurp::ViewHelpers)

describe S3lurp::ViewHelpers do
  view = ActionView::Base.new

  it "should return a form" do
    (!!view.s3_direct_form_tag().match(/<form /)).should be_true
  end

  it 'should have a configuration hash' do
    
  end
end

