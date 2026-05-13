import Foundation

struct RemoteApp: Codable, Identifiable {
    // دروستکردنی ئایدییەکی جیاواز بۆ هەر یارییەک
    var id: String { UUID().uuidString }
    
    let name: String
    let version: String?
    let iconURL: String?
    let downloadURL: String
    let size: String?
    let hack: [String]? // لیستەکەی تۆ بۆ هاکەکان
    
    // ئەمە وا دەکات هاکەکان پێکەوە بنووسێنێت وەک وەسفێکی جوان پیشانی بدات
    var description: String? {
        return hack?.joined(separator: " • ")
    }
    
    enum CodingKeys: String, CodingKey {
        case name = "name"
        case version = "version"
        case iconURL = "image"        // 💡 لێرەدا گۆڕیمان بۆ image
        case downloadURL = "url"      // 💡 لێرەدا گۆڕیمان بۆ url
        case size = "size"
        case hack = "hack"
    }
}
