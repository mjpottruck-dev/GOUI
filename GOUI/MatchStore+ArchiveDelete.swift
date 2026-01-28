import Foundation

extension MatchStore {

    /// Deletes the correct items from the real archive even if the list is filtered/sorted.
    func deleteArchived(at offsets: IndexSet, from filtered: [MatchRecord]) {
        let idsToDelete = offsets.compactMap { idx in
            filtered.indices.contains(idx) ? filtered[idx].id : nil
        }

        var a = self.archive
        a.removeAll { idsToDelete.contains($0.id) }
        self.archive = a
    }
}

