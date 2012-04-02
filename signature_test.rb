require 'rubygems'
require 'cgi'
require 'time'
require 'uri'
require 'openssl'
# require 'hmac-sha2'
require 'base64'

    good_sig = "Nace%2BU3Az4OhN7tISqgs1vdLBHBEijWcBeCqL5xN9xg%3D"
    string_to_sign = 
"GET
ecs.amazonaws.com
/onca/xml
AWSAccessKeyId=0S5GFRG3KV8DE9QP9FR2&AssociateTag=PutYourAssociateTagHere&Keywords=harry%20potter&Operation=ItemSearch&SearchIndex=Books&Service=AWSECommerceService&Timestamp=2012-03-19T16%3A49%3A31.000Z&Version=2011-08-01"
    # hmac = HMAC::SHA256.new(1234567890)
    # digest = OpenSSL::Digest::Digest.new('sha2')
    # hmac.update(string_to_sign)
    key = "0S5GFRG3KV8DE9QP9FR2"
    digest = OpenSSL::Digest.new("sha256")
    hmac = OpenSSL::HMAC.digest(digest, "FBkLuKpppfojj2A5+QmZ8D28kevoD9pTQJkY8C6n", string_to_sign)

#    hmac = OpenSSL::HMAC.hexdigest('sha256', '1234567890', string_to_sign)

	signature = Base64.encode64(hmac).chomp
    #signature = Base64.encode64(hmac.digest).chomp
    #puts hmac
    puts CGI.escape(signature)
