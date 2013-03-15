# s3lurp - Browser Uploads Direct to S3

direct s3 upload form helper

## Installation

Add this line to your application's Gemfile:

    gem 's3lurp'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install s3lurp

## Usage

### Configuration

in config/initializers/s3lurp.rb

```ruby
S3lurp.configure do |config|
  config.s3_bucket = "bucket_of_holding"
  config.s3_access_key = "S3_PUBLICK_KEY"
  config.s3_secret_key = "S3_SECRET_KEY"
```

### View Helper

The meat of this gem is the view helper: s3_direct_form_tag

```ruby
= s3_direct_form_tag({:key => '/posts/@post_id/photos/uuid/${filename}'})
```

TODO: documentation

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Credits

