class UsersController < ApplicationController

  before_filter :authenticate_user!

  load_and_authorize_resource
  
  def index
    @users = User.all
  end

  
  def show
    @user = User.find(params[:id])
    @items = @user.items
    @amazon_item = Item.get_amazon_item(params[:item][:asin]) if params[:item]
  end

  
  def new
    @user = User.new
  end

  
  def edit
    @user = User.find(params[:id])
  end

  
  def create
    @user = User.new(params[:user])
    if @user.save
      redirect_to @user, notice: 'User was successfully created.' 
    else
      render :new
    end
  end


  def update
    @user = User.find(params[:id])
    if @user.update_attributes(params[:user])
      redirect_to @user, notice: 'User was successfully updated.' 
    else
      render :edit
    end
  end


  def destroy
    @user = User.find(params[:id])
    @user.destroy
    redirect_to users_url
  end


  def add_amazon_item
    @user = User.find(params[:id])
    @item = @user.build_amazon_item(params)
    if @item.save
      @item.prices.create(:amount => @item.current_price)
      redirect_to user_path(@user), :notice => "Item Added!" 
    else
      render :new
    end
  end


  def update_prices
    @user = User.find(params[:id])
    @user.update_all_item_prices
    redirect_to user_path(@user), :notice => "Prices Updated!"
  end
  


end
