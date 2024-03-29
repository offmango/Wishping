# SECRETS!  ADD THIS FILE TO YOUR .GITIGNORE!  IT SHOULD NOT BE COMMITTED!
#
# If an s3.yml file exists, use the key, secret key, and bucket values from there.
# Otherwise, pull them from the environment.]
#
# To set environment variables on Heroku, see https://devcenter.heroku.com/articles/config-vars

S3 = {}
if File.exists?("#{Rails.root}/config/s3.yml")
  s3_config = YAML.load_file("#{Rails.root}/config/s3.yml")
  S3[:key] = s3_config[::Rails.env]['key']
  S3[:secret] = s3_config[::Rails.env]['secret']
  S3[:tag] = s3_config[::Rails.env]['tag']
  # S3[:bucket] = s3_config[Rails.env]['bucket']
else
  S3[:key] = ENV['S3_KEY']
  S3[:secret] = ENV['S3_SECRET']
  S3[:tag] = ENV['S3_TAG']
  # S3[:bucket] = ENV['S3_BUCKET']
end

ENV['AWS_URL'] = "http://webservices.amazon.com/onca/xml"