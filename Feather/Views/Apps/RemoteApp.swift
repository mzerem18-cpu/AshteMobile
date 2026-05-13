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
    
    // 💡 ئەمە وێنەکان چاک دەکات بە لکاندنی لینکی سایتەکەت
    var fullIconURL: URL? {
        guard let path = iconURL else { return nil }
        return URL(string: "https://ashtemobile.site/\(path)")
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
