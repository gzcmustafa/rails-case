class ProductsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :sync_from_sheet
  before_action :set_product, only: %i[show edit update destroy]

  # Ürünleri listeleme
  def index
    @products = Product.all
  end

  # Yeni ürün formu
  def new
    @product = Product.new
  end

  # Ürün oluşturma
  def create
    @product = Product.new(product_params)
    if @product.save
      redirect_to products_path
    else
      render :new
    end
  end

  # Ürün gösterme
  def show; end

  # Ürün düzenleme formu
  def edit; end

  # Ürün güncelleme
  def update
    if @product.update(product_params)
      redirect_to products_path
    else
      render :edit
    end
  end

  # Ürün silme
  def destroy
    @product.destroy
    redirect_to products_path
  end

  # Google Sheet'ten veri çekme (tek yönlü senkronizasyon)
  def sync_from_sheet
    google_sheet_id = ENV['GOOGLE_SHEET_ID']
    
    if google_sheet_id.blank?
      flash[:alert] = 'GOOGLE_SHEET_ID is not defined. Please check your environment variables.'
      redirect_to products_path
      return
    end
    
    service = ProductSyncService.new(google_sheet_id: google_sheet_id)
    result = service.call
    
    if result[:errors].empty?
      flash[:notice] = 'Products Synced Successfully'
    else
      flash[:alert] = "Sync completed with #{result[:errors].count} errors."
    end
    
    redirect_to products_path
  end

  private

  # set_product metodu: id ile ürünü bulur
  def set_product
    @product = Product.find(params[:id])
  end

  # Strong params
  def product_params
    params.require(:product).permit(:name, :price, :stock, :category)
  end
end
