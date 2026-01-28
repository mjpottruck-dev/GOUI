import Foundation

private let archiveKey = "GoUI.archive.matches.v1"

/// The real storage backing variable (use this internally to avoid name clashes)
var matchArchive: [MatchRecord] {
    get { loadArchive() }
    set { saveArchive(newValue) }
}

/// Backwards-compatible alias for older files that reference `archive`
var archive: [MatchRecord] {
    get { matchArchive }
    set { matchArchive = newValue }
}

private func saveArchive(_ matches: [MatchRecord]) {
    do {
        let data = try JSONEncoder().encode(matches)
        UserDefaults.standard.set(data, forKey: archiveKey)
    } catch {
        // don't crash on encoding errors
    }
}

private func loadArchive() -> [MatchRecord] {
    guard let data = UserDefaults.standard.data(forKey: archiveKey) else { return [] }
    do {
        return try JSONDecoder().decode([MatchRecord].self, from: data)
    } catch {
        return []
    }
}

