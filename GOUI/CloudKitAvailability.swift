import CloudKit
import Foundation

enum CloudKitAvailability {
    static var isAvailable: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return true
        #endif
    }

    static func defaultContainer() -> CKContainer? {
        guard isAvailable else { return nil }
        return CKContainer.default()
    }
}

struct CloudKitUnavailableError: LocalizedError {
    var errorDescription: String? {
        "CloudKit is unavailable on this device."
    }
}
