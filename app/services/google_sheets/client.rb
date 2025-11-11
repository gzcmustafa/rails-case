require 'googleauth'
require 'google/apis/sheets_v4'

module GoogleSheets
  class Client
    SCOPE = [Google::Apis::SheetsV4::AUTH_SPREADSHEETS].freeze

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

    def get_values(spreadsheet_id, range)
      @service.get_spreadsheet_values(spreadsheet_id, range).values || []
    end
  end
end

