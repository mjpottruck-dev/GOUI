import Foundation

extension MatchStore {

    /// Backwards-compatible: UI can call `matchStore.archive`
    var archive: [MatchRecord] {
        get { matchArchive }
        set { matchArchive = newValue }
    }

    func addToArchive(_ record: MatchRecord) {
        var a = matchArchive
        a.insert(record, at: 0)
        matchArchive = a
    }

    func deleteFromArchive(where predicate: (MatchRecord) -> Bool) {
        var a = matchArchive
        a.removeAll(where: predicate)
        matchArchive = a
    }
}

