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
        case SportCatalog.footballID:
            return [
                GameTemplate(
                    id: "football_flag_4x8",
                    name: "Flag (4x8 min)",
                    sportID: sportID,
                    periodDurationOverrides: Array(repeating: 8 * 60, count: 4),
                    periodCountOverrides: 4,
                    defaultRosterMode: .teamDefaults
                ),
                GameTemplate(
                    id: "football_hs_4x12",
                    name: "HS Tackle (4x12 min)",
                    sportID: sportID,
                    periodDurationOverrides: Array(repeating: 12 * 60, count: 4),
                    periodCountOverrides: 4,
                    defaultRosterMode: .teamDefaults
                )
            ]
        case SportCatalog.crossCountryID:
            return [
                GameTemplate(
                    id: "xc_2mi",
                    name: "2 Mile",
                    sportID: sportID,
                    periodDurationOverrides: nil,
                    periodCountOverrides: nil,
                    defaultRosterMode: .fullRoster
                ),
                GameTemplate(
                    id: "xc_3mi",
                    name: "3 Mile",
                    sportID: sportID,
                    periodDurationOverrides: nil,
                    periodCountOverrides: nil,
                    defaultRosterMode: .fullRoster
                ),
                GameTemplate(
                    id: "xc_5k",
                    name: "5K",
                    sportID: sportID,
                    periodDurationOverrides: nil,
                    periodCountOverrides: nil,
                    defaultRosterMode: .fullRoster
                )
            ]
        case SportCatalog.wrestlingID:
            return [
                GameTemplate(
                    id: "wrestling_hs_standard",
                    name: "HS Standard (3x2 min)",
                    sportID: sportID,
                    periodDurationOverrides: Array(repeating: 2 * 60, count: 3),
                    periodCountOverrides: 3,
                    defaultRosterMode: .teamDefaults
                )
            ]
        case SportCatalog.swimmingID:
            return [
                GameTemplate(
                    id: "swim_50_free",
                    name: "50 Free",
                    sportID: sportID,
                    periodDurationOverrides: nil,
                    periodCountOverrides: nil,
                    defaultRosterMode: .fullRoster
                ),
                GameTemplate(
                    id: "swim_100_free",
                    name: "100 Free",
                    sportID: sportID,
                    periodDurationOverrides: nil,
                    periodCountOverrides: nil,
                    defaultRosterMode: .fullRoster
                ),
                GameTemplate(
                    id: "swim_100_fly",
                    name: "100 Fly",
                    sportID: sportID,
                    periodDurationOverrides: nil,
                    periodCountOverrides: nil,
                    defaultRosterMode: .fullRoster
                ),
                GameTemplate(
                    id: "swim_200_free",
                    name: "200 Free",
                    sportID: sportID,
                    periodDurationOverrides: nil,
                    periodCountOverrides: nil,
                    defaultRosterMode: .fullRoster
                ),
                GameTemplate(
                    id: "swim_200_im",
                    name: "200 IM",
                    sportID: sportID,
                    periodDurationOverrides: nil,
                    periodCountOverrides: nil,
                    defaultRosterMode: .fullRoster
                ),
                GameTemplate(
                    id: "swim_400_relay",
                    name: "400 Free Relay",
                    sportID: sportID,
                    periodDurationOverrides: nil,
                    periodCountOverrides: nil,
                    defaultRosterMode: .fullRoster
                ),
                GameTemplate(
                    id: "swim_custom",
                    name: "Custom Event",
                    sportID: sportID,
                    periodDurationOverrides: nil,
                    periodCountOverrides: nil,
                    defaultRosterMode: .fullRoster
                )
            ]
        case SportCatalog.baseballID:
            return [
                GameTemplate(
                    id: "baseball_6_innings",
                    name: "6 Innings",
                    sportID: sportID,
                    periodDurationOverrides: nil,
                    periodCountOverrides: 6,
                    defaultRosterMode: .teamDefaults
                ),
                GameTemplate(
                    id: "baseball_7_innings",
                    name: "7 Innings",
                    sportID: sportID,
                    periodDurationOverrides: nil,
                    periodCountOverrides: 7,
                    defaultRosterMode: .teamDefaults
                ),
                GameTemplate(
                    id: "baseball_9_innings",
                    name: "9 Innings",
                    sportID: sportID,
                    periodDurationOverrides: nil,
                    periodCountOverrides: 9,
                    defaultRosterMode: .teamDefaults
                )
            ]
        case SportCatalog.softballID:
            return [
                GameTemplate(
                    id: "softball_6_innings",
                    name: "6 Innings",
                    sportID: sportID,
                    periodDurationOverrides: nil,
                    periodCountOverrides: 6,
                    defaultRosterMode: .teamDefaults
                ),
                GameTemplate(
                    id: "softball_7_innings",
                    name: "7 Innings",
                    sportID: sportID,
                    periodDurationOverrides: nil,
                    periodCountOverrides: 7,
                    defaultRosterMode: .teamDefaults
                ),
                GameTemplate(
                    id: "softball_9_innings",
                    name: "9 Innings",
                    sportID: sportID,
                    periodDurationOverrides: nil,
                    periodCountOverrides: 9,
                    defaultRosterMode: .teamDefaults
                )
            ]
        case SportCatalog.trackID:
            return [
                GameTemplate(
                    id: "track_100",
                    name: "100m",
                    sportID: sportID,
                    periodDurationOverrides: nil,
                    periodCountOverrides: nil,
                    defaultRosterMode: .fullRoster
                ),
                GameTemplate(
                    id: "track_200",
                    name: "200m",
                    sportID: sportID,
                    periodDurationOverrides: nil,
                    periodCountOverrides: nil,
                    defaultRosterMode: .fullRoster
                ),
                GameTemplate(
                    id: "track_400",
                    name: "400m",
                    sportID: sportID,
                    periodDurationOverrides: nil,
                    periodCountOverrides: nil,
                    defaultRosterMode: .fullRoster
                ),
                GameTemplate(
                    id: "track_800",
                    name: "800m",
                    sportID: sportID,
                    periodDurationOverrides: nil,
                    periodCountOverrides: nil,
                    defaultRosterMode: .fullRoster
                ),
                GameTemplate(
                    id: "track_1600",
                    name: "1600m",
                    sportID: sportID,
                    periodDurationOverrides: nil,
                    periodCountOverrides: nil,
                    defaultRosterMode: .fullRoster
                ),
                GameTemplate(
                    id: "track_3200",
                    name: "3200m",
                    sportID: sportID,
                    periodDurationOverrides: nil,
                    periodCountOverrides: nil,
                    defaultRosterMode: .fullRoster
                ),
                GameTemplate(
                    id: "track_4x100",
                    name: "4x100 Relay",
                    sportID: sportID,
                    periodDurationOverrides: nil,
                    periodCountOverrides: nil,
                    defaultRosterMode: .fullRoster
                ),
                GameTemplate(
                    id: "track_4x400",
                    name: "4x400 Relay",
                    sportID: sportID,
                    periodDurationOverrides: nil,
                    periodCountOverrides: nil,
                    defaultRosterMode: .fullRoster
                ),
                GameTemplate(
                    id: "track_long_jump",
                    name: "Long Jump",
                    sportID: sportID,
                    periodDurationOverrides: nil,
                    periodCountOverrides: nil,
                    defaultRosterMode: .fullRoster
                ),
                GameTemplate(
                    id: "track_shot_put",
                    name: "Shot Put",
                    sportID: sportID,
                    periodDurationOverrides: nil,
                    periodCountOverrides: nil,
                    defaultRosterMode: .fullRoster
                ),
                GameTemplate(
                    id: "track_custom",
                    name: "Custom Event",
                    sportID: sportID,
                    periodDurationOverrides: nil,
                    periodCountOverrides: nil,
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
