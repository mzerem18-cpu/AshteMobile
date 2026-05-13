import Foundation

struct RemoteApp: Codable, Identifiable {
    var id: String { bundleIdentifier ?? UUID().uuidString }
    let name: String
    let bundleIdentifier: String?
    let version: String?
    let iconURL: String?
    let downloadURL: String
    let description: String?
}
