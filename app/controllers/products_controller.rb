class ProductsController < ApplicationController
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
    spreadsheet_id =  ENV['PRODUCTS_SHEET_ID'] #TODO iki seçenek
    service = ProductSyncService.new(spreadsheet_id: spreadsheet_id)
    result = service.call

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
