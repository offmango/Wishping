class ItemsController < ApplicationController
  
  before_filter :authenticate_user!   # Devise authentication

  # load_and_authorize_resource :user
  # load_and_authorize_resource :through => :user         # Cancan authorization
  # skip_authorize_resource :only => :show
  # skip_authorize_resource :user, :only => :show

  def index
    @items = Item.find_all_by_user_id(params[:user_id])
    @amazon_item = Item.get_amazon_item(params[:item][:asin]) if params[:item]
      
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @items }
    end
  end


  def show
    @item = Item.find(params[:id])
    @price_array = []
    @item.prices.each {|price| @price_array << price.amount }

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @item }
    end
  end


  def edit
    @item = Item.find(params[:id])
  end


  def create
    @item = current_user.items.create()
    if @item.save
      redirect_to @item, notice: 'Item was successfully created.' 
    else
      render :new
    end
  end


  def update
    @item = Item.find(params[:id])

    if @item.update_attributes(params[:item])
      redirect_to user_items_path, :notice => "Item Added!"
    else
      render :edit
    end
  end


  def destroy
    @user = User.find(params[:user_id])
    @item = Item.find(params[:id])
    @item.destroy
    redirect_to user_path(@user)
  end


end
