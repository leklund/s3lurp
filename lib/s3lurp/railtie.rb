module S3lurp
  class Railtie < Rails::Railtie
    initializer "s3lurp.configure" do

    end

    initializer "s3lurp.view_helpers" do
      ActionView::Base.send :include, ViewHelpers
    end

  end
end
