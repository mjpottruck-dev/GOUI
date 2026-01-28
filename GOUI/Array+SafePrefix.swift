import Foundation

extension Array {
    func safePrefix(_ n: Int) -> [Element] {
        guard n > 0 else { return [] }
        return Array(prefix(n))
    }
}

