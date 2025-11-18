class SyncProductsFromSheetService
  def initialize(google_sheet_id:, client: nil)
    @google_sheet_id = google_sheet_id
    @client = client || GoogleSheets::Client.new
    @errors = []
  end

  attr_reader :errors

  def call
    # Sheet'ten veri çek
    rows = @client.get_values(@google_sheet_id, 'Sheet1')
    return { errors: [], error: 'Sheet is empty or cannot be read.' } if rows.empty?

    # rows bir dizi olacak ve içinde her bir satırın bulunduğu dizi olacak.
    # Örnek: [["name", "price", "stock", "category", "errors"], ["Product 1", "100", "10", "Category 1", ""], ...]

    # Header'ı alır
    # Örn: ["uuid", "name", "price", "stock", "category", "errors"]
    header = rows.shift.map(&:to_s).map(&:strip).map(&:downcase)

    # sütunların indexlerini bulur yani her sütunun pozisyonunu bulmuş oluruz.
    uuid_idx     = header.index('uuid')     # 0 yani A sütunu
    name_idx     = header.index('name')     # 1 yani B sütunu
    price_idx    = header.index('price')    # 2 yani C sütunu
    stock_idx    = header.index('stock')    # 3 yani D sütunu
    category_idx = header.index('category') # 4 yani E sütunu
    # Hata mesajlarını yazacağımız sütun.
    errors_idx   = header.index('error') # 5 yani F sütunu

    # Sheet'teki tüm UUID'leri tutacak (silme işlemi için)
    sheet_uuids = []

    # Ürün satırları, Sheet'te header'dan bir sonrasına (2. satır) denk gelir
    rows.each_with_index do |row, index|
      row ||= []
      sheet_row_number = index + 2 # Header 1. satır, ürünler 2.satırdan başlar

      raw_uuid    = row[uuid_idx] if uuid_idx

      # Satır tamamen boşsa (name, price, stock, category hiç yoksa) bu satırı tamamen atla
      raw_name     = row[name_idx]
      raw_price    = row[price_idx]
      raw_stock    = row[stock_idx]
      raw_category = row[category_idx]

      if [raw_name, raw_price, raw_stock, raw_category].all? { |v| v.to_s.strip.empty? }
        # Boş satır -> ne DB'ye kaydet ne de hata yaz
        next
      end

      # name değişkenini errors dizinde kullanmak için bu şekilde yaptım. Tekrar strip yazmamak için.
      name = raw_name&.strip

      # UUID boşsa (özellikle Sheet'te yeni eklenen satırlar) → yeni bir UUID üret
      uuid = raw_uuid.to_s.strip
      if uuid.empty?
        uuid = SecureRandom.uuid
        write_uuid_to_sheet(sheet_row_number, uuid_idx, uuid) if uuid_idx
      end

      # attrs: { uuid: "xxx", name: "Product 1", price: 100, stock: 10, category: "Category 1" }
      attrs = {
        uuid: uuid,
        name: name,
        price: raw_price&.to_f,
        stock: raw_stock&.to_i,
        category: raw_category&.strip
      }

      # Sheet'ten gelen tüm UUID'leri topla (silme kontrolü için)
      sheet_uuids << uuid

      # UUID'ye göre bul veya yeni oluştur
      product = Product.find_or_initialize_by(uuid: uuid)

      # attrs hash'indeki her key-value çiftini product nesnesinin attribute'larına atamak
      product.assign_attributes(attrs)

      if product.valid?
        if product.new_record?
          product.save! # Yeni kayıt oluştur
        elsif product.changed? # herhangi bir attribute değişmiş mi ?
          product.save! # SQL updateyi çalıştırıp günceller.
        end

        # Başarılı satır için hata sütununu temizle (varsa)
        write_error_to_sheet(sheet_row_number, errors_idx, nil) if errors_idx
      else
        error_message = product.errors.full_messages.join(', ')
        @errors << { name: attrs[:name], error: error_message }

        # Sheet içinde ilgili satırın "errors" sütununa hata mesajını yaz
        write_error_to_sheet(sheet_row_number, errors_idx, error_message) if errors_idx
      end
    end

    # DB'de olup sheet'te olmayanları siler
    # UUID'ye göre kontrol ediyoruz (isim/other alanları yerine - daha güvenilir)
    Product.find_each do |p|
      next if sheet_uuids.include?(p.uuid)

      p.destroy # sheette yoksa db'den siler
    end

    { errors: errors, error: nil }
  end

  private

  # sütun index'i alıp Excel/Sheets sütun harfine çevirir
  def column_letter(index)
    return nil if index.nil?

    result = ''
    while index >= 0
      result = (index % 26 + 'A'.ord).chr + result
      index = index / 26 - 1
    end
    result
  end

  # Belirli bir satır ve UUID sütunu için UUID değerini Sheet'e yazar
  def write_uuid_to_sheet(row_number, uuid_idx, uuid)
    return if uuid_idx.nil?

    col_letter = column_letter(uuid_idx)
    range = "Sheet1!#{col_letter}#{row_number}"
    values = [[uuid.to_s]]
    @client.update_values(@google_sheet_id, range, values)
  end

  # Belirli bir satır ve errors sütunu için hata mesajını Sheet'e yazar
  def write_error_to_sheet(row_number, errors_idx, message)
    return if errors_idx.nil?

    col_letter = column_letter(errors_idx)
    range = "Sheet1!#{col_letter}#{row_number}"
    values = [[message.to_s]] # nil gelirse boş string yazılır
    @client.update_values(@google_sheet_id, range, values)
  end
end


