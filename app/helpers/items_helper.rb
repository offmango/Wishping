module ItemsHelper

	def row_class(item)
		if item.highest_price > 0 and item.lowest_price > 0 and item.highest_price != item.lowest_price
			if item.current_price >= item.highest_price
				"highest-price"
			elsif item.current_price <= item.lowest_price
				"lowest-price"
			end
		end
	end


	def amazon_link(asin)
		"http://www.amazon.com/gp/product/#{asin}?tag=#{S3[:tag]}"
	end
	
end
