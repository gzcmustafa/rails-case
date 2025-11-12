class ProductSyncService
    def initialize(spreadsheet_id:, client: nil)
      @spreadsheet_id = spreadsheet_id
      @client = client || GoogleSheets::Client.new
      @errors = []
    end

    attr_reader :errors
  
    def call
      # Sheet'ten veri çek
      rows = @client.get_values(@spreadsheet_id, 'Sheet1')
      return { error: 'Sheet boş veya okunamadı' } if rows.empty?

      #  rows bir dizi olacak ve içinde her bir satırın bulunduğu dizi olacak. 
      # Örnek: [["name", "price", "stock", "category"], ["Product 1", "100", "10", "Category 1"], ["Product 2", "200", "20", "Category 2"]]
  
      # Header'ı alır
      header = rows.shift.map(&:to_s).map(&:strip).map(&:downcase) #her elemanı stringe çeviri,boşlukları temizler ve küçük harfe çevirir
      # sütunların indexlerini bulur yani her sütunun pozisyonunu bulmuş oluruz.
      name_idx = header.index('name') #0
      price_idx = header.index('price') #1
      stock_idx = header.index('stock') #2
      category_idx = header.index('category') #3
  
      # Sheet'teki tüm external_id'leri tutacak (silme işlemi için)
      sheet_external_ids = []

      rows.each do |row|
        # Boş satırları filtrele (name kontrolü ile)
        name = row[name_idx]&.strip
        next if name.blank?  # Name yoksa boş satır, atla
        
        # name_idx: 0, price_idx: 1, stock_idx: 2, category_idx: 3
        # attrs: { name: "Product 1", price: 100, stock: 10, category: "Category 1" }
        attrs = {
          name: name,
          price: row[price_idx]&.to_f,
          stock: row[stock_idx]&.to_i,
          category: row[category_idx]&.strip
        }
        
        # External ID oluştur: Satırın içeriğine göre benzersiz imza (signature)
        # Bu sayede aynı isimdeki ürünler bile ayrı tutulur (farklı özelliklere sahipse)
        # Format: "name|category|price|stock"
        # Örnek: "Ürün A|Elektronik|100.0|10"
        external_id = "#{attrs[:name]}|#{attrs[:category]}|#{attrs[:price]}|#{attrs[:stock]}"
        sheet_external_ids << external_id
        
        # External ID'ye göre bul veya yeni oluştur
        # Bu endüstri standardı yaklaşım: Her dış sistem kaydı için benzersiz ID
        product = Product.find_or_initialize_by(external_id: external_id)
        
        # attrs hash'indeki her key-value çiftini product nesnesinin attribute'larına atamak
        product.assign_attributes(attrs) 
        if product.valid?
          if product.new_record?
            product.save! # Yeni kayıt oluştur
          elsif product.changed? # herhangi bir attribute değişmiş mi ?
            product.save! # SQL updateyi çalıştırıp günceller.
          end
        else
          @errors << { name: attrs[:name], error: product.errors.full_messages.join(', ') }
        end
      end

      # DB'de olup sheet'te olmayanları siler
      # External ID'ye göre kontrol ediyoruz (isim yerine - daha güvenilir)
      Product.find_each do |p|
        next if sheet_external_ids.include?(p.external_id)
        p.destroy #sheete yoksa db'den siler
      end

      { errors: errors }
    end
  end
  