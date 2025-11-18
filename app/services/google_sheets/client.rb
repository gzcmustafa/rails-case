require 'googleauth'
require 'google/apis/sheets_v4'

module GoogleSheets
  class Client
    SCOPE = [Google::Apis::SheetsV4::AUTH_SPREADSHEETS].freeze

    #Google Sheets APIye bağlanır ve service account ile kimlik doğrulama yapar
    def initialize(service_account_json_path: Rails.root.join('config','service_account.json'))
      @service = Google::Apis::SheetsV4::SheetsService.new
      @service.client_options.application_name = 'ProductsSync'
      authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: File.open(service_account_json_path),
        scope: SCOPE
      )
      authorizer.fetch_access_token!
      @service.authorization = authorizer
    end

    # Sheetdeki verileri çeker
    def get_values(google_sheet_id, range)
      @service.get_spreadsheet_values(google_sheet_id, range).values || []
    end

    # Belirtilen aralıktaki hücreleri temizler (içerikleri siler)
    def clear_values(google_sheet_id, range)
      request = Google::Apis::SheetsV4::ClearValuesRequest.new
      @service.clear_values(google_sheet_id, range, request)
    end

    # Belirtilen aralığa değer yazar (var olan hücreleri günceller)
    # Hem güncelleme için hemde errors mesajı yazdırmak için kullanıyoruz.
    def update_values(google_sheet_id, range, values, value_input_option: 'RAW')
      value_range = Google::Apis::SheetsV4::ValueRange.new(values: values)
      @service.update_spreadsheet_value(
        google_sheet_id,
        range,
        value_range,
        value_input_option: value_input_option
      )
    end

    # Sheet'in sonuna yeni satır ekler
    def append_values(google_sheet_id, range, values, value_input_option: 'RAW')
      value_range = Google::Apis::SheetsV4::ValueRange.new(values: values)
      @service.append_spreadsheet_value(
        google_sheet_id,
        range,
        value_range,
        value_input_option: value_input_option
      )
    end
  end
end

