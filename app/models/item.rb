class Item < ActiveRecord::Base

  require 'time'
  require 'uri'
	require 'openssl'
  require 'base64'
  include HTTParty

	belongs_to :user
  has_many :prices

  default_scope order("created_at DESC")
	
	# Search Amazon based on specific search index and keywords
  # See http://docs.amazonwebservices.com/AWSECommerceService/latest/DG/ItemSearch.html
  def self.amazon_item_search(search_index, keywords)
    # Escape the keywords, replacing spaces with plus signs
    escaped_keywords = CGI.escape(keywords)
    url_params = {
      'AssociateTag' => S3[:tag],
      'AWSAccessKeyId' => S3[:key],
      'Keywords' => escaped_keywords,
      'Operation' => 'ItemSearch',
      'SearchIndex' => search_index,
      'Service' => 'AWSECommerceService',
      'Timestamp' => Time.now.utc.iso8601,    # TIME HAS TO BE IN ISO8601 or signature won't match
      'Version' => '2011-08-01'
    }
    canonical_querystring = create_canonical_querystring(url_params)
    encoded_signature = encode_signature(canonical_querystring) 
    url_params['Signature'] = escaped_signature
    # UNESCAPE the keywords (this took me forever to figure out, and there's probably a better way to do it)
    url_params['Keywords'] = url_params['Keywords'].gsub(/%20/,'+')
    querystring = create_querystring(url_params)
    puts "#{ENV['AWS_URL']}?#{querystring}"
	end


  # Retrieve an item's information using its ASIN and response group
  # More on Amazon's response groups here: http://docs.amazonwebservices.com/AWSECommerceService/latest/DG/ItemLookup.html
  def self.amazon_item_lookup(asin, response_group)
    url_params = {
      'AssociateTag' => S3[:tag],
      'AWSAccessKeyId' => S3[:key],
      'Operation' => 'ItemLookup',
      'ItemId' => asin,
      'ResponseGroup' => response_group,
      'Service' => 'AWSECommerceService',
      'Timestamp' => Time.now.utc.iso8601,    # TIME HAS TO BE IN ISO8601 or signature won't match
      'Version' => '2011-08-01'
    }
    canonical_querystring = create_canonical_querystring(url_params)
    encoded_signature = encode_signature(canonical_querystring)
    url_params['Signature'] = encoded_signature
    querystring = create_querystring(url_params)
    get("#{ENV['AWS_URL']}?#{querystring}")
    # puts `curl -X"GET" "#{amazon_endpoint}?#{querystring}" -A"simple ruby aws sdb wrapper"`
    # puts xmlreturn
    # puts "#{amazon_endpoint}?#{querystring}"
  end


  # Returns a hash with keys "item_attributes" and "amazon_price" if there are no errors,
  # or a hash with key "errors" if there are errors
  def self.get_amazon_item(asin)
    amazon_item = self.get_amazon_item_attributes(asin)
  end


  # Get an Amazon item's attributes via asin;
  # - returns a string if there's an error, otherwise returns a hash of the attributes
  def self.get_amazon_item_attributes(asin)
    amazon_item_attributes = {} 
    amazon_lookup_response = self.amazon_item_lookup(asin, "ItemAttributes")
    amazon_item_attributes["errors"] = self.amazon_lookup_error(amazon_lookup_response)
    return amazon_item_attributes if amazon_item_attributes["errors"].present?
    amazon_item_attributes["title"] = amazon_lookup_response["ItemLookupResponse"]["Items"]["Item"]["ItemAttributes"]["Title"]
    amazon_item_attributes["list_price"] = amazon_lookup_response["ItemLookupResponse"]["Items"]["Item"]["ItemAttributes"]["ListPrice"]["Amount"].to_f / 100
    amazon_item_attributes["asin"] = asin
    price = self.get_amazon_item_price(asin)
    if price.kind_of?(Float)
      amazon_item_attributes["amazon_price"] = price
    else
      amazon_item_attributes["errors"] = price
    end
    amazon_item_attributes
  end

  # # get_amazon_item_attributes returns a hash like this:
  # {
  #   "Binding"=>"Lawn & Patio", 
  #   "Brand"=>"Weber", 
  #   "CatalogNumberList"=>
  #     {"CatalogNumberListElement"=>"1421001"}, 
  #   "Color"=>"Black", 
  #   "Department"=>"Garden & Outdoor", 
  #   "EAN"=>"0077924002205", 
  #   "EANList"=>
  #     {"EANListElement"=>"0077924002205"}, 
  #   "Feature"=>
  #     ["The Weber Performer charcoal grill features a  Touch-N-Go gas-ignition system", 
  #       "It has a total cooking are of 363 square-inches", 
  #       "It comes with a rolling steel-frame cart, work table;,3 tool hooks, and a lid-mounted thermometer", 
  #       "Also included are 2 charcoal fuel holders, and a charcoal storage container", 
  #       "Measures 28-1/2-by-50-1/4-by-40 inches"], 
  #   "ItemDimensions"=>
  #     {
  #       "Height"=>"4000", 
  #       "Length"=>"2850", 
  #       "Weight"=>"13700", 
  #       "Width"=>"5025"
  #     }, 
  #   "Label"=>"Weber", 
  #   "ListPrice"=>
  #     {
  #       "Amount"=>"42900", 
  #       "CurrencyCode"=>"USD", 
  #       "FormattedPrice"=>"$429.00"
  #     }, 
  #   "Manufacturer"=>"Weber", 
  #   "Model"=>"1421001", 
  #   "MPN"=>"1421001", 
  #   "NumberOfItems"=>"1", 
  #   "PackageDimensions"=>
  #     {
  #       "Height"=>"2000", 
  #       "Length"=>"3900", 
  #       "Weight"=>"9600", 
  #       "Width"=>"2850"
  #     }, 
  #   "PackageQuantity"=>"1", 
  #   "PartNumber"=>"1421001", 
  #   "ProductGroup"=>"Lawn & Patio", 
  #   "ProductTypeName"=>"OUTDOOR_LIVING", 
  #   "Publisher"=>"Weber", 
  #   "SKU"=>"1421001", 
  #   "Studio"=>"Weber", 
  #   "Title"=>"Weber 1421001 Performer Charcoal Grill, Black", 
  #   "UPC"=>"077924002205", 
  #   "UPCList"=>
  #     {"UPCListElement"=>"077924002205"}, 
  #   "Warranty"=>"2-year limited warranty"
  # } 


  # Get an Amazon item's attributes via asin;
  # - returns a string if there's an error, otherwise returns the price as a boolean
  def self.get_amazon_item_price(asin)
    amazon_lookup_response = self.amazon_item_lookup(asin, "Offers")
    amazon_error = amazon_lookup_error(amazon_lookup_response)
    return amazon_error if amazon_error.present?
    amazon_item_price = amazon_lookup_response["ItemLookupResponse"]["Items"]["Item"]["Offers"]["Offer"]["OfferListing"]["Price"]["Amount"].to_f / 100
  end


  def self.amazon_lookup_error(response)
    if response["ItemLookupResponse"]["Items"]["Request"]["Errors"].present?
      response["ItemLookupResponse"]["Items"]["Request"]["Errors"]["Error"]["Message"]
    end
  end




  def update_prices
    new_current_price = Item.get_amazon_item_price(self.asin)
    if new_current_price.kind_of?(Float)  # If it's not a float, it's an error
      self.prices.create(:amount => new_current_price)
      # If the current price has changed, update the current, high and low prices as needed
      if self.current_price != new_current_price
        self.current_price = new_current_price
        self.highest_price = new_current_price if new_current_price > self.highest_price
        self.lowest_price = new_current_price if new_current_price < self.lowest_price
      end
      self.price_updated_at = Time.now
      self.save!
    else
      puts new_current_price
    end
    
  end


  private

  def self.create_canonical_querystring(params)
    # Create the querystring, making sure to escape to remove colons and commas.  
    # Use gsub to make sure the proper space character is used
    params.sort.collect { |key, value| [CGI.escape(key.to_s), CGI.escape(value.to_s).gsub(/%2B/, '%20')].join('=') }.join('&')
  end


  def self.create_querystring(params)
    # Create the querystring with the new params.  DON'T escape the params this time
    params.collect { |key, value| [key, value].join('=') }.join('&') 
  end


  def self.encode_signature(canonical_querystring)
    # Append the querystring to the proper amazon header
    # Don't tab the string_to_sign over!  Signature won't encode properly!  Screw your pretty margins!
    string_to_sign = 
"GET
webservices.amazon.com
/onca/xml
#{canonical_querystring}"
    digest = OpenSSL::Digest.new("sha256")
    hmac = OpenSSL::HMAC.digest(digest, S3[:secret], string_to_sign)
    signature = Base64.encode64(hmac).chomp
    # Escape the plus (+) and equal (=) characters in the signature
    # Make sure to use chomp, since this adds a newline at the end
    escaped_signature = URI.escape(signature, "+=/")
  end


end
