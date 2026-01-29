import Foundation

enum RosterMode: String, Codable, CaseIterable {
    case teamDefaults
    case fullRoster
}

struct GameTemplate: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let sportID: String
    let periodDurationOverrides: [TimeInterval]?
    let periodCountOverrides: Int?
    let defaultRosterMode: RosterMode
}

enum GameTemplateCatalog {
    static func templates(for sportID: String) -> [GameTemplate] {
        switch sportID {
        case SportCatalog.basketballID:
            return [
                GameTemplate(
                    id: "basketball_youth_4x8",
                    name: "4x8 min (Youth)",
                    sportID: sportID,
                    periodDurationOverrides: Array(repeating: 8 * 60, count: 4),
                    periodCountOverrides: 4,
                    defaultRosterMode: .teamDefaults
                ),
                GameTemplate(
                    id: "basketball_hs_4x10",
                    name: "4x10 min (HS)",
                    sportID: sportID,
                    periodDurationOverrides: Array(repeating: 10 * 60, count: 4),
                    periodCountOverrides: 4,
                    defaultRosterMode: .teamDefaults
                ),
                GameTemplate(
                    id: "basketball_college_2x16",
                    name: "2x16 min (College)",
                    sportID: sportID,
                    periodDurationOverrides: Array(repeating: 16 * 60, count: 2),
                    periodCountOverrides: 2,
                    defaultRosterMode: .teamDefaults
                )
            ]
        case SportCatalog.waterPoloID:
            return [
                GameTemplate(
                    id: "waterpolo_standard_4x8",
                    name: "4x8 min (Standard)",
                    sportID: sportID,
                    periodDurationOverrides: Array(repeating: 8 * 60, count: 4),
                    periodCountOverrides: 4,
                    defaultRosterMode: .teamDefaults
                ),
                GameTemplate(
                    id: "waterpolo_youth_4x7",
                    name: "4x7 min (Youth)",
                    sportID: sportID,
                    periodDurationOverrides: Array(repeating: 7 * 60, count: 4),
                    periodCountOverrides: 4,
                    defaultRosterMode: .teamDefaults
                )
            ]
        case SportCatalog.volleyballID:
            return [
                GameTemplate(
                    id: "volleyball_best_of_3",
                    name: "Best of 3",
                    sportID: sportID,
                    periodDurationOverrides: nil,
                    periodCountOverrides: 3,
                    defaultRosterMode: .teamDefaults
                ),
                GameTemplate(
                    id: "volleyball_best_of_5",
                    name: "Best of 5",
                    sportID: sportID,
                    periodDurationOverrides: nil,
                    periodCountOverrides: 5,
                    defaultRosterMode: .teamDefaults
                )
            ]
        case SportCatalog.tennisID:
            return [
                GameTemplate(
                    id: "tennis_best_of_3",
                    name: "Best of 3 Sets",
                    sportID: sportID,
                    periodDurationOverrides: nil,
                    periodCountOverrides: 3,
                    defaultRosterMode: .fullRoster
                ),
                GameTemplate(
                    id: "tennis_best_of_5",
                    name: "Best of 5 Sets",
                    sportID: sportID,
                    periodDurationOverrides: nil,
                    periodCountOverrides: 5,
                    defaultRosterMode: .fullRoster
                )
            ]
        case SportCatalog.golfID:
            return [
                GameTemplate(
                    id: "golf_9_holes",
                    name: "9 Holes",
                    sportID: sportID,
                    periodDurationOverrides: nil,
                    periodCountOverrides: 9,
                    defaultRosterMode: .fullRoster
                ),
                GameTemplate(
                    id: "golf_18_holes",
                    name: "18 Holes",
                    sportID: sportID,
                    periodDurationOverrides: nil,
                    periodCountOverrides: 18,
                    defaultRosterMode: .fullRoster
                )
            ]
        default:
            return []
        }
    }

    static func defaultTemplate(for sportID: String) -> GameTemplate? {
        templates(for: sportID).first
    }

    static func template(for sportID: String, templateID: String?) -> GameTemplate? {
        guard let templateID else { return defaultTemplate(for: sportID) }
        return templates(for: sportID).first { $0.id == templateID } ?? defaultTemplate(for: sportID)
    }
}
