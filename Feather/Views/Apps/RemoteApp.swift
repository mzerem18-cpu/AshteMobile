import Foundation

struct RemoteApp: Codable, Identifiable {
    var id: String { UUID().uuidString }
    
    let name: String
    let version: String?
    let iconURL: String?
    let downloadURL: String
    let size: String?
    let hack: [String]? 
    
    var description: String? {
        return hack?.joined(separator: " • ")
    }
    
    var fullIconURL: URL? {
        guard let path = iconURL else { return nil }
        return URL(string: "https://ashtemobile.site/\(path)")
    }
    
    // 🔥 چارەسەری کێشەکە: ئەمە کۆدی Base64 دەکاتەوە بە لینکی ڕاستەقینەی داونلۆد
    var actualDownloadURL: URL? {
        if let data = Data(base64Encoded: downloadURL),
           let decodedString = String(data: data, encoding: .utf8),
           let url = URL(string: decodedString) {
            return url
        }
        return URL(string: downloadURL)
    }
    
    enum CodingKeys: String, CodingKey {
        case name = "name"
        case version = "version"
        case iconURL = "image"
        case downloadURL = "url"
        case size = "size"
        case hack = "hack"
    }
}
