import Foundation

struct AuthUser: Identifiable, Codable, Hashable {
    var id: String { userID }
    let userID: String
    var displayName: String
    var role: UserRole
    var userRecordName: String?
    var createdAt: Date
    var updatedAt: Date
}
