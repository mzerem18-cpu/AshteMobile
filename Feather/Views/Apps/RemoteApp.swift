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
    
    // 🔥 چارەسەری کۆتایی بۆ لینکەکان (بۆشایی و کێشەی Base64 چارەسەر دەکات)
    var actualDownloadURL: URL? {
        let cleanStr = downloadURL.trimmingCharacters(in: .whitespacesAndNewlines)
        var base64Data = Data(base64Encoded: cleanStr, options: .ignoreUnknownCharacters)
        
        // ئەگەر کۆدەکە کەمایەسی هەبوو چاکی دەکاتەوە
        if base64Data == nil {
            let padded = cleanStr.padding(toLength: ((cleanStr.count + 3) / 4) * 4, withPad: "=", startingAt: 0)
            base64Data = Data(base64Encoded: padded, options: .ignoreUnknownCharacters)
        }
        
        if let data = base64Data, let decoded = String(data: data, encoding: .utf8) {
            // ئەمە بۆشایی ناو لینکەکان چارەسەر دەکات (وەک Pirate Ships)
            let safeURLString = decoded.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? decoded
            return URL(string: safeURLString)
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
