class Price < ActiveRecord::Base

	belongs_to :item

	default_scope order("created_at DESC")
	
end
