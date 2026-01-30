import Foundation
import StoreKit

final class SubscriptionManager: ObservableObject {
    @Published private(set) var currentPlan: Plan {
        didSet { savePlan() }
    }

    @Published private(set) var lastPurchaseError: String? = nil

    private let planKey = "subscription.currentPlan"
    private let exportsKey = "subscription.exportsByMonth"
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init() {
        if let raw = UserDefaults.standard.string(forKey: planKey),
           let plan = Plan(rawValue: raw) {
            currentPlan = plan
        } else {
            currentPlan = .free
        }
    }

    var entitlements: Entitlements {
        switch currentPlan {
        case .free: return .free
        case .playerPro: return .playerPro
        case .coachPro: return .coachPro
        case .clubPro: return .clubPro
        }
    }

    func purchase(plan: Plan) async {
        AnalyticsService.shared.log(.purchaseStarted, metadata: ["plan": plan.rawValue])
        #if DEBUG
        await MainActor.run {
            currentPlan = plan
            lastPurchaseError = nil
        }
        AnalyticsService.shared.log(.purchaseCompleted, metadata: ["plan": plan.rawValue])
        return
        #else
        do {
            try await refreshFromStoreKit()
            await MainActor.run {
                currentPlan = plan
                lastPurchaseError = nil
            }
            AnalyticsService.shared.log(.purchaseCompleted, metadata: ["plan": plan.rawValue])
        } catch {
            await MainActor.run {
                lastPurchaseError = error.localizedDescription
            }
            AnalyticsService.shared.log(.purchaseFailed, metadata: ["plan": plan.rawValue])
        }
        #endif
    }

    func restorePurchases() async {
        #if DEBUG
        await MainActor.run {
            lastPurchaseError = nil
        }
        return
        #else
        do {
            try await AppStore.sync()
            try await refreshFromStoreKit()
            await MainActor.run {
                lastPurchaseError = nil
            }
        } catch {
            await MainActor.run {
                lastPurchaseError = error.localizedDescription
            }
        }
        #endif
    }

    func updatePlanForDebug(_ plan: Plan) {
        #if DEBUG
        currentPlan = plan
        #endif
    }

    func canExport() -> Bool {
        if entitlements.unlimitedExports {
            return true
        }
        return exportsThisMonth() < SubscriptionLimits.freeExportsPerMonth
    }

    func recordExport() {
        guard !entitlements.unlimitedExports else { return }
        var map = exportsByMonth()
        let key = monthKey()
        map[key, default: 0] += 1
        saveExports(map)
    }

    func exportsThisMonth() -> Int {
        let key = monthKey()
        return exportsByMonth()[key, default: 0]
    }

    func canCreateClip(existingCount: Int) -> Bool {
        if entitlements.videoClipsUnlimited {
            return true
        }
        return existingCount < entitlements.clipsPerGameLimit
    }

    private func savePlan() {
        UserDefaults.standard.set(currentPlan.rawValue, forKey: planKey)
    }

    private func exportsByMonth() -> [String: Int] {
        guard let data = UserDefaults.standard.data(forKey: exportsKey),
              let map = try? decoder.decode([String: Int].self, from: data) else {
            return [:]
        }
        return map
    }

    private func saveExports(_ map: [String: Int]) {
        guard let data = try? encoder.encode(map) else { return }
        UserDefaults.standard.set(data, forKey: exportsKey)
    }

    private func monthKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }

    @MainActor
    private func refreshFromStoreKit() async throws {
        var hasPlayerPro = false
        var hasCoachPro = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            switch transaction.productID {
            case SubscriptionProducts.playerProMonthly:
                hasPlayerPro = true
            case SubscriptionProducts.coachProMonthly:
                hasCoachPro = true
            default:
                break
            }
        }

        if hasCoachPro {
            currentPlan = .coachPro
        } else if hasPlayerPro {
            currentPlan = .playerPro
        } else {
            currentPlan = .free
        }
    }
}
