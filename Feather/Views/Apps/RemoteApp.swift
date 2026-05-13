import Foundation

struct RemoteApp: Codable, Identifiable {
    let name: String
    let version: String?
    let iconURL: String?
    let bannerURL: String?
    let category: String?
    let downloadURL: String?
    let size: String?
    let status: String?
    let hack: [String]?
    
    var id: String { name } 
    
    var safeIconURL: URL? {
        guard let path = iconURL else { return nil }
        return URL(string: "https://ashtemobile.site/\(path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? path)")
    }
    
    var safeBannerURL: URL? {
        guard let path = bannerURL else { return nil }
        return URL(string: "https://ashtemobile.site/\(path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? path)")
    }
    
    var actualDownloadURL: URL? {
        guard let dl = downloadURL else { return nil }
        let cleanStr = dl.trimmingCharacters(in: .whitespacesAndNewlines)
        var base64Data = Data(base64Encoded: cleanStr, options: .ignoreUnknownCharacters)
        
        if base64Data == nil {
            let padded = cleanStr.padding(toLength: ((cleanStr.count + 3) / 4) * 4, withPad: "=", startingAt: 0)
            base64Data = Data(base64Encoded: padded, options: .ignoreUnknownCharacters)
        }
        
        if let data = base64Data, let decoded = String(data: data, encoding: .utf8) {
            let safeURLString = decoded.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? decoded
            return URL(string: safeURLString)
        }
        return URL(string: dl)
    }
    
    enum CodingKeys: String, CodingKey {
        case name = "name", version = "version", iconURL = "image"
        case bannerURL = "banner", category = "category", downloadURL = "url"
        case size = "size", status = "status", hack = "hack"
    }
}
