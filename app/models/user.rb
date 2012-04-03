class User < ActiveRecord::Base
	# Include default devise modules. Others available are:
	# :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
	devise :database_authenticatable, :registerable,
	         :recoverable, :rememberable, :trackable, :validatable, :omniauthable

	# Setup accessible (or protected) attributes for your model
	attr_accessible :email, :password, :password_confirmation, :remember_me, :first_name, :last_name

	has_many :items

	def self.find_for_facebook_oauth(access_token, signed_in_resource=nil)
		data = access_token.extra.raw_info
		if user = User.where(:email => data.email).first
		    user
		else # Create a user with a stub password. 
		    User.create!(:email => data.email, :password => Devise.friendly_token[0,20]) 
		end
	end


	def admin?
		self.role == "admin"
	end


	def update_all_item_prices
		self.items.each {|item| item.update_prices}
	end


	def full_name
		"#{self.try(:first_name)} #{self.try(:last_name)}"
	end


	def build_amazon_item(params)
		item = self.items.build
    	item.name = params[:name]
    	item.asin = params[:asin]
    	item.current_price = params[:price]
    	item.highest_price = item.current_price
    	item.lowest_price = item.current_price
    	item.price_updated_at = Time.now
    	item
    end
	  
end
