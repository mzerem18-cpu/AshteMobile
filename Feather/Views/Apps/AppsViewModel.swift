import Foundation
import SwiftUI

class AppsViewModel: ObservableObject {
    @Published var apps: [RemoteApp] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchApps() {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "https://ashtemobile.site/ipaas.json") else {
            self.errorMessage = "Invalid URL"
            self.isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                guard let data = data else { return }
                do {
                    let decodedData = try JSONDecoder().decode([RemoteApp].self, from: data)
                    self.apps = decodedData
                } catch {
                    self.errorMessage = "Failed to decode JSON: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}
