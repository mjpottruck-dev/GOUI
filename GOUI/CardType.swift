// CardType.swift
import Foundation

enum CardType: String, CaseIterable, Identifiable, Codable, Hashable {
    case yellow = "Yellow"
    case red = "Red"

    var id: String { rawValue }
}

