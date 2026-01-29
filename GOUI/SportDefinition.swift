import Foundation

struct SportDefinition: Hashable {
    var supportsGoalie: Bool
    var supportsPositions: Bool
}

extension SportDefinition {
    static let soccer = SportDefinition(supportsGoalie: true, supportsPositions: true)
    static let current = SportDefinition.soccer
}
