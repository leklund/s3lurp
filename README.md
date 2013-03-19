# s3lurp - Browser Uploads Direct to S3

direct s3 upload Rails form helper

## Installation

Add this line to your application's Gemfile:

    gem 's3lurp'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install s3lurp

### Configuration

S3lurp has many options that can be configured globally or passed
to the helper via a hash.

#### AWS S3 Setup

There are three options required for buckets that are not public-write:

* `s3_bucket` - The name of the bucket where files go
* `s3_access_key` - This is your AWS Access Key ID
* `s3_secret_ley` - Your AWS Secret Accss Key


These three options can be set via a yaml config file, an initializer, or ENV vars.


    ENV['S3_BUCKET']
    ENV['S3_ACCESS_KEY']
    ENV['S3_SECRET_KEY']

Another way to set up these options is to us an initializer.

In config/initializers/s3lurp.rb

```ruby
S3lurp.configure do |config|
  config.s3_bucket = "bucket_of_holding"
  config.s3_access_key = "some_acces_key"
  config.s3_secret_key = "keep_it_secret"
```

Finally you can use use a yaml file to load the configuration.

```ruby
# config/initializers/s3lurp.rb
S3lurp.congigure do |config|
  config.file = 's3lurp.yml'
end
# config/s3lurp.yml
development:
  s3_bucket: "dev_bucket"
  s3_access_key: "dev_key"
  s3_secret_key: "dev_secret"
production:
  s3_bucket: "prod_bucket"
  s3_access_key: "prod_key"
  s3_secret_key: "prod_secret"
```

Using a yaml conifg file allows you to use different settings for different
environments. Note: It's not necessary to provide environment based settings. The
yaml can just be a set of key/value pairs without any grouping by environment.

#### S3lurp Config Example

Here is an exmaple of how to configure s3lurp using Heroku.

Setup your ENV variables for heroku and for local use.
For more on Heroku config see here: https://devcenter.heroku.com/articles/config-vars

```
$ heroku config:add S3_KEY=asdfg12345 S3_SECRET=qwertyu0987622`
$ export S3_KEY=asdfg12345
$ export S3_SECRET=qwertyu0987622
```

Set up some defaults with an initialzer

```ruby
# config/initializers/s3lurp.rb
S3lurp.congigure do |config|
  config.acl = 'public-read'
  config.minutes_valid = '600'
  config.max_file_size = 10.megabytes
  config.min_file_size = 1024
end
```

And now in your view you can call

    s3_direct_form_tag({:key => 'photos/uuid/${filename}'})

This will generate a complete form with a file input and a submit tag. The form
will contain all the necessary hidden fields to perform a direct upload to S3.

#### Configuration Options

Many of these options correspond to the HTML form fields that AWS accepts. This documentation will
be helpful: http://docs.aws.amazon.com/AmazonS3/latest/dev/HTTPPOSTForms.html

All of these can be congured in an initializer, a yaml config file, or passed directly
to the helper in a hash.

| Option                   | Description |
|--------------------------|-------------|
|__:file__                 | Name of yaml file located in the config directory. Contains any of the options listed in this table. Should be set inside a configuration block via an initializer. |
|__:s3\_bucket__           | AWS S3 bucket name where files will stored. Can also be configured via ENV['S3_BUCKET']. __Required__|
|__:s3\_access\_key__      | AWS Access Key. Can also be configured via ENV['S3_ACCESS_KEY']. __Required for buckets that are not public-write.__|
|__:s3\_secret\_key__      | AWS AWS Secret Accss Key. Can also be configured via ENV['S3_SECRET_KEY']. __Required for buckets that are not public-write.__|
|__:key__                  | This is the key for the S3 object. To use the filename of the upload, use the vairable ${filename} (see example). __Required__|
|__:acl__                  | Sepecies an S3 access control list. Valid values: `private` `public-read` `public-read-write` `authenticated-read` `bucket-owner-read` `bucket-owner-full-control`. _Default_: `private` |
|__:cache\_control__       | Refer to [S3 PUT Object documentation](http://docs.aws.amazon.com/AmazonS3/2006-03-01/API/RESTObjectPUT.html)|
|__:content\_disposition__ | Refer to [S3 PUT Object documentation](http://docs.aws.amazon.com/AmazonS3/2006-03-01/API/RESTObjectPUT.html)|
|__:content\_encoding__    | Refer to [S3 PUT Object documentation](http://docs.aws.amazon.com/AmazonS3/2006-03-01/API/RESTObjectPUT.html)|
|__:expires__              | Refer to [S3 PUT Object documentation](http://docs.aws.amazon.com/AmazonS3/2006-03-01/API/RESTObjectPUT.html)|
|__:content\_type__        | A standard MIME type describing the format of the contents. _Default_: `binary/octet-stream`. Note: S3 will not automatically determine the content\_type.|
|__:success\_action\_redirect__| The URL to which a client is redirected after a successful upload. S3 will append the bucket, key, and etag as query parameters to the URL |
|__:success\_action\_status__| HTTP status code returned upon successful upload if success_action_redirect is not set. _Default:_ 204. |
|__:min\_file\_size__      | Size in bytes of minimum allowed file size _Default:_ 0 |
|__:max\_file\_size__      | Size in bytes of maximum allowed file size _Default:_ 10485760 |
|__:amz\_meta\_tags__      | Hash of additional metadata to be stored with the object. Stored on S3 as `x-amz-meta-#{key} = #{value}` |
|__:minutes\_valid__       | Length of time in minutes that the generated form is valid. _Default:_ 360 |
|__:form\_html\_options__  | Hash of additional options that is passed to the form_tag contructor. |
|__:file\_field\_tag\_accept__ | Sets the accept parameter of the file field tag. [?](http://www.w3.org/TR/html-markup/input.file.html#input.file.attrs.accept) |
|__:submit\_tag__          | HTML string containing code for the input or button that will handle form submission. This is optional and if not included a basic submit tag will be generated for the form. |
|__:submit\_tag\_value__   | Override the value of the standard generated submit tag. _Default:_ "Upload" |
|__:submit\_tag\_options__ | Hash of options passed to the submit_tag generator. |


### Examples

coming soon.

## Credits

With inspiration from:

* [d2s3](https://github.com/mwilliams/d2s3)
* [Sinatra-S3-Direct-Upload](https://github.com/waynehoover/Sinatra-S3-Direct-Upload)

## License

Copyright &copy; 2013 Lukas Eklund, released under the MIT license
