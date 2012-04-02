require 'rubygems' 
# require 'amazon/aws/search' 
include Amazon::AWS 
include Amazon::AWS::Search 

il = ItemLookup.new( 'ASIN', { 'ItemId' => '1430231149', 'MerchantId' => 'Amazon' } ) 
rg = ResponseGroup.new( 'Medium' ) 
req = Request.new 
resp = req.search( il, rg ) 
item = resp.item_lookup_response.items.item 
attribs = item.item_attributes 
title = attribs.title 
asin = item.asin 
sales_rank = item.sales_rank 
publication_date = attribs.publication_date 
puts "#{title} was released on #{publication_date}"

#locale = 'us' cache = false key_id = 'PASTE_YOUR_ACCESS_KEY_HERE' secret_key_id = 'PASTE_YOUR_SECRET_KEY_HERE'
