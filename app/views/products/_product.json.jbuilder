json.extract! product, :id, :name, :price, :stock, :category, :created_at, :updated_at
json.url product_url(product, format: :json)
