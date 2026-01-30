import Foundation

struct ClubInviteCodes: Codable, Hashable {
    var coachCode: String
    var adminCode: String
}

struct Club: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var teamIDs: [UUID]
    var adminIDs: [String]
    var inviteCodes: ClubInviteCodes
}

private struct LegacyClub: Codable {
    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var teamIDs: [UUID]
    var adminIDs: [UUID]
    var inviteCodes: ClubInviteCodes

    func toClub() -> Club {
        Club(
            id: id,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt,
            teamIDs: teamIDs,
            adminIDs: adminIDs.map { $0.uuidString },
            inviteCodes: inviteCodes
        )
    }
}

final class ClubStore: ObservableObject {
    @Published private(set) var clubs: [Club] = [] {
        didSet { save() }
    }

    private let fileURL: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = docs.appendingPathComponent("clubs.json")
        load()
    }

    func createClub(name: String, adminID: String, teamIDs: [UUID]) -> Club {
        let now = Date()
        let club = Club(
            id: UUID(),
            name: name,
            createdAt: now,
            updatedAt: now,
            teamIDs: teamIDs,
            adminIDs: [adminID],
            inviteCodes: ClubInviteCodes(coachCode: Self.makeInviteCode(), adminCode: Self.makeInviteCode())
        )
        clubs.append(club)
        return club
    }

    func updateClub(_ club: Club) {
        guard let idx = clubs.firstIndex(where: { $0.id == club.id }) else { return }
        var updated = club
        updated.updatedAt = Date()
        clubs[idx] = updated
    }

    func regenerateInviteCodes(for clubID: UUID) {
        guard let idx = clubs.firstIndex(where: { $0.id == clubID }) else { return }
        clubs[idx].inviteCodes = ClubInviteCodes(coachCode: Self.makeInviteCode(), adminCode: Self.makeInviteCode())
        clubs[idx].updatedAt = Date()
    }

    func joinClub(with code: String, userID: String) -> (club: Club, role: UserRole)? {
        if let club = clubs.first(where: { $0.inviteCodes.adminCode == code }) {
            var updated = club
            if !updated.adminIDs.contains(userID) {
                updated.adminIDs.append(userID)
            }
            updateClub(updated)
            return (updated, .coach)
        }

        if let club = clubs.first(where: { $0.inviteCodes.coachCode == code }) {
            return (club, .coach)
        }

        return nil
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              !data.isEmpty else {
            clubs = []
            return
        }
        if let decoded = try? JSONDecoder().decode([Club].self, from: data) {
            clubs = decoded
            return
        }
        if let legacy = try? JSONDecoder().decode([LegacyClub].self, from: data) {
            clubs = legacy.map { $0.toClub() }
        } else {
            clubs = []
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(clubs) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }

    private static func makeInviteCode() -> String {
        let characters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<6).compactMap { _ in characters.randomElement() })
    }
}
