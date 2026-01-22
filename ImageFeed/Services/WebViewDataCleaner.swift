import WebKit

final class WebViewDataCleaner {

    static let shared = WebViewDataCleaner()
    private init() {}

    func clear(completion: @escaping () -> Void) {
        let dataStore = WKWebsiteDataStore.default()
        
        let dataTypes: Set<String> = [
            WKWebsiteDataTypeCookies,
            WKWebsiteDataTypeLocalStorage,
            WKWebsiteDataTypeSessionStorage,
            WKWebsiteDataTypeIndexedDBDatabases,
            WKWebsiteDataTypeWebSQLDatabases
        ]
        
        dataStore.fetchDataRecords(ofTypes: dataTypes) { records in
            dataStore.removeData(ofTypes: dataTypes, for: records) {
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }
}
