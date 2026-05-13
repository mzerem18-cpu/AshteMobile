import Foundation
import IDeviceSwift // بۆ ئەوەی مۆدێلەکان بناسێت

struct RemoteApp: Codable, Identifiable {
    var id: String { bundleIdentifier ?? UUID().uuidString }
    
    let name: String
    let bundleIdentifier: String?
    let version: String?
    let iconURL: String?
    let downloadURL: String
    let description: String?
    
    enum CodingKeys: String, CodingKey {
        case name = "name"
        case bundleIdentifier = "bundleID" // ڕێکی بخە لەگەڵ ناوی ناو JSONـەکەت
        case version = "version"
        case iconURL = "icon"
        case downloadURL = "download"
        case description = "description"
    }
}

// 💡 ئەم بەشە زۆر گرنگە بۆ ئەوەی ڕاستەوخۆ لەناو InstallProgressView کار بکات
extension RemoteApp: AppInfoPresentable {
    var currentName: String? { return name }
    var iconData: Data? { return nil } // وێنەکە لە ئینتەرنێتەوە دێت
}
