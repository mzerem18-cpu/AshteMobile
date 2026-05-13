import Foundation

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
        case bundleIdentifier = "bundleID"
        case version = "version"
        case iconURL = "icon"
        case downloadURL = "download"
        case description = "description"
    }
}
