import Foundation
import UniformTypeIdentifiers

extension UTType {
    static let goUIRoster = UTType(exportedAs: "com.maxpottruck.goui.roster+json", conformingTo: .json)
}

struct RosterExport: Codable {
    var formatVersion: Int = 1
    var exportedAt: Date = Date()
    var team: Team

    var playerCount: Int { team.players.count }
}

enum RosterTransferError: LocalizedError {
    case emptyRoster
    case invalidData

    var errorDescription: String? {
        switch self {
        case .emptyRoster:
            return "Roster is empty. Add players before exporting."
        case .invalidData:
            return "The selected file is not a valid roster export."
        }
    }
}

enum RosterTransferService {
    static func exportFile(for team: Team) throws -> URL {
        guard !team.players.isEmpty else {
            throw RosterTransferError.emptyRoster
        }

        let payload = RosterExport(team: team)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(payload)

        let directory = FileManager.default.temporaryDirectory
        let safeName = sanitizedFilename(team.name.isEmpty ? "Team" : team.name)
        let url = directory.appendingPathComponent("\(safeName)-Roster.json")
        try data.write(to: url, options: [.atomic])
        return url
    }

    static func importRoster(from url: URL) throws -> RosterExport {
        let needsScoped = url.startAccessingSecurityScopedResource()
        defer {
            if needsScoped {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: url)

        if let payload = try? JSONDecoder().decode(RosterExport.self, from: data) {
            guard !payload.team.players.isEmpty else { throw RosterTransferError.emptyRoster }
            return payload
        }

        if let team = try? JSONDecoder().decode(Team.self, from: data) {
            guard !team.players.isEmpty else { throw RosterTransferError.emptyRoster }
            return RosterExport(team: team)
        }

        throw RosterTransferError.invalidData
    }

    private static func sanitizedFilename(_ name: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let replaced = name.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
        return String(replaced).replacingOccurrences(of: "--", with: "-")
    }
}
