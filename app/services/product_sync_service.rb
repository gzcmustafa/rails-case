class ProductSyncService
    def initialize(spreadsheet_id:, sheet_name: 'Sheet1', client: nil)
      @spreadsheet_id = spreadsheet_id
      @sheet_name = sheet_name
      @client = client || GoogleSheets::Client.new
      @errors = []
      @processed = { created: 0, updated: 0, skipped: 0, deleted: 0 }
    end
  
    attr_reader :errors, :processed
  
    def call
      # Sheet'ten veri çek
      rows = @client.get_values(@spreadsheet_id, @sheet_name)
      return { error: 'Sheet boş veya okunamadı' } if rows.empty?
  
      # Header'ı alır
      header = rows.shift.map(&:to_s).map(&:strip).map(&:downcase)
      name_idx = header.index('name')
      price_idx = header.index('price')
      stock_idx = header.index('stock')
      category_idx = header.index('category')
  
      sheet_names = []
  
      rows.each do |row|
        #sheeteki verileri alır
        attrs = {
          name: row[name_idx]&.strip,
          price: row[price_idx]&.to_f,
          stock: row[stock_idx]&.to_i,
          category: row[category_idx]&.strip
        }
        sheet_names << attrs[:name]
        #DB'deki ürünü bulur veya yeni oluşturur
        product = Product.find_or_initialize_by(name: attrs[:name])
        #güncelleme yapar
        product.assign_attributes(attrs)
        if product.valid?
          if product.changed?
            product.save!
            @processed[:updated] += 1
          else
            @processed[:skipped] += 1
          end
        else
          @errors << { name: attrs[:name], error: product.errors.full_messages.join(', ') }
        end
      end
  
      # DB’de olup sheet’te olmayanları siler
      Product.find_each do |p|
        next if sheet_names.include?(p.name)
        p.destroy #sheete yoksa db'den siler
        @processed[:deleted] += 1
      end
  
      { processed: processed, errors: errors }
    end
  end
  