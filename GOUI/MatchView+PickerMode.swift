import Foundation

// Re-introduces MatchView.PickerMode so PlayerFieldPicker compiles again.
extension MatchView {

    enum PickerMode: String, CaseIterable, Identifiable, Codable {

        // ✅ What PlayerFieldPicker expects
        case primary

        // Common “who are you picking?” flows
        case scorer
        case assister
        case shooter
        case cardedPlayer

        // Keeper-related
        case keeper

        // Sub flow
        case subIn
        case subOut

        // Fallback
        case generic

        var id: String { rawValue }
    }
}

