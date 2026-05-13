import Foundation

class AppsViewModel: ObservableObject {
    @Published var apps: [RemoteApp] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchApps() {
        // تەنها بۆ تاقیکردنەوەیە
    }
}
