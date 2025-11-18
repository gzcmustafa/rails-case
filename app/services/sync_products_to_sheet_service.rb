class SyncProductsToSheetService
  SHEET_NAME = 'Sheet1'.freeze
  HEADER     = ['UUID', 'Name', 'Price', 'Stock', 'Category', 'Error'].freeze

  def initialize(google_sheet_id: ENV['GOOGLE_SHEET_ID'], client: nil)
    @google_sheet_id = google_sheet_id
    @client = client || GoogleSheets::Client.new
  end

  # Basit strateji:
  # - Sabit header'ı her sync'te A1:F1 aralığına yazar
  # - DB'deki tüm ürünlerden satır listesi üretir
  # - Header'dan sonraki kısmı (A2'den aşağısı) tek seferde DB'ye göre yeniden yazar
  def sync_all_products
    return if @google_sheet_id.blank?

    # 0) Header'ı sabit olarak yaz
    @client.update_values(@google_sheet_id, "#{SHEET_NAME}!A1:F1", [HEADER])

    # 1) DB'den tüm ürünleri al
    products = Product.order(:created_at)

    # 2) Her ürün için [uuid, name, price, stock, category, ""] satırı oluştur
    data_rows = products.map do |product|
      [
        product.uuid,
        product.name,
        product.price.to_f,
        product.stock,
        product.category,
        '' # Error sütunu, burada boş bırakıyoruz
      ]
    end

    # 3) Hangi sütuna kadar yazacağımızı bul (header uzunluğuna göre)
    last_col_index  = HEADER.length - 1
    last_col_letter = column_letter(last_col_index) # index'i sütun harfine çevirir.

    # 4) Önce eski verileri temizle (header hariç A2 dan başlayarak)
    clear_range = "#{SHEET_NAME}!A2:#{last_col_letter}1000" # A2’den F1000’e kadar olan hücreler.
    @client.clear_values(@google_sheet_id, clear_range)

    # 5) DB'de ürün yoksa sadece temizleyip çık
    return if data_rows.empty?

    # 6) DB'den gelen satırları A2'den başlayarak tek seferde yaz
    last_row_number = 1 + data_rows.length
    range  = "#{SHEET_NAME}!A2:#{last_col_letter}#{last_row_number}"
    values = data_rows

    @client.update_values(@google_sheet_id, range, values)
  end

  private

  # index -> Excel/Sheets sütun harfi
  def column_letter(index)
    return nil if index.nil?

    result = ''
    while index >= 0
      result = (index % 26 + 'A'.ord).chr + result
      index = index / 26 - 1
    end
    result
  end
end


