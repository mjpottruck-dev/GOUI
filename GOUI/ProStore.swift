import Foundation
import StoreKit
import SwiftUI
import UIKit

/// What GoalStats Pro unlocks. Used for the paywall's perk list and to explain
/// which feature the coach tapped when the paywall opens.
enum ProFeature: String, CaseIterable, Identifiable {
    case aiRecaps, seasonReports, voice, rosterImport, unlimitedTeams, smartSubs, exports, liveActivity

    var id: String { rawValue }

    var title: String {
        switch self {
        case .aiRecaps: return "AI match recaps"
        case .seasonReports: return "AI season reports"
        case .voice: return "Voice stat logging"
        case .rosterImport: return "Roster import from a photo"
        case .unlimitedTeams: return "Unlimited teams"
        case .smartSubs: return "Smart subs & line changes"
        case .exports: return "PDF reports & MaxPreps export"
        case .liveActivity: return "Lock-screen Live Activity"
        }
    }

    var detail: String {
        switch self {
        case .aiRecaps: return "A written recap and insights for every game, seconds after the whistle."
        case .seasonReports: return "Form, top performers and what to work on, across the whole season."
        case .voice: return "Say \"goal seven, assist ten\" and keep your eyes on the game."
        case .rosterImport: return "Snap a roster sheet and every player is added for you."
        case .unlimitedTeams: return "Coach more than one team, each with its own stats."
        case .smartSubs: return "Nudges when a player is due on, and swap a whole line at once."
        case .exports: return "Share a clean stats PDF with parents, or upload straight to MaxPreps."
        case .liveActivity: return "Score and clock on your lock screen and Dynamic Island."
        }
    }

    var icon: String {
        switch self {
        case .aiRecaps: return "sparkles"
        case .seasonReports: return "chart.line.uptrend.xyaxis"
        case .voice: return "mic.fill"
        case .rosterImport: return "camera.viewfinder"
        case .unlimitedTeams: return "person.3.fill"
        case .smartSubs: return "arrow.triangle.2.circlepath"
        case .exports: return "doc.richtext"
        case .liveActivity: return "iphone.badge.play"
        }
    }
}

/// GoalStats Pro subscription (StoreKit 2): $9.99/month or $99.99/year.
///
/// App Store Connect setup (one time): create an auto-renewable subscription group
/// "GoalStats Pro" with the two product IDs below. For simulator testing, the
/// scheme uses GoalStats.storekit, so purchases work without App Store Connect.
@MainActor
final class ProStore: ObservableObject {
    static let shared = ProStore()

    static let monthlyID = "com.maxpottruck.GOUI.pro.monthly"
    static let yearlyID = "com.maxpottruck.GOUI.pro.yearly"
    static let productIDs = [yearlyID, monthlyID]

    /// Links the paywall must show (App Store guideline 3.1.2).
    /// TODO before release: replace the privacy URL with your published policy.
    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let privacyURL = URL(string: "https://goalstats.app/privacy")!

    @Published private(set) var products: [Product] = []
    @Published private(set) var isPro: Bool = ProAccess.isPro
    @Published private(set) var activePlanID: String? = nil
    @Published private(set) var isLoading = false
    @Published var errorMessage: String? = nil


    private var updatesTask: Task<Void, Never>? = nil

    private init() {
        updatesTask = Task { [weak self] in
            // Renewals, refunds, purchases on another device, Ask to Buy approvals.
            for await update in Transaction.updates {
                if case .verified(let transaction) = update {
                    await transaction.finish()
                }
                await self?.refreshEntitlements()
            }
        }
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit { updatesTask?.cancel() }

    var monthly: Product? { products.first { $0.id == Self.monthlyID } }
    var yearly: Product? { products.first { $0.id == Self.yearlyID } }

    /// "Save 17%" for yearly vs 12 months of monthly.
    var yearlySavingsPercent: Int? {
        guard let m = monthly?.price, let y = yearly?.price, m > 0 else { return nil }
        let full = m * 12
        let saved = (full - y) / full * 100
        return Int(NSDecimalNumber(decimal: saved).doubleValue.rounded())
    }

    // MARK: - Loading

    func loadProducts() async {
        guard products.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let loaded = try await Product.products(for: Self.productIDs)
            products = loaded.sorted { $0.price > $1.price } // yearly first
        } catch {
            errorMessage = "Couldn't load plans. Check your connection and try again."
        }
    }

    func refreshEntitlements() async {
        var active: String? = nil
        var jws: String? = nil
        for await result in Transaction.currentEntitlements {
            guard case .verified(let t) = result,
                  Self.productIDs.contains(t.productID),
                  t.revocationDate == nil else { continue }
            if let expiry = t.expirationDate, expiry < Date() { continue }
            active = t.productID
            jws = result.jwsRepresentation
        }
        activePlanID = active
        // Apple-signed proof of the subscription; the AI backend verifies it.
        UserDefaults.standard.set(jws, forKey: AIClient.transactionKey)
        // Cached so Pro works offline at kickoff; StoreKit re-checks on every launch.
        UserDefaults.standard.set(active != nil, forKey: ProAccess.cacheKey)
        isPro = ProAccess.isPro
    }

    // MARK: - Purchase / restore

    /// Returns true when the coach now has Pro.
    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    errorMessage = "The purchase couldn't be verified."
                    return false
                }
                await transaction.finish()
                await refreshEntitlements()
                Haptics.medium()
                return isPro
            case .pending:
                errorMessage = "Purchase pending approval (e.g. Ask to Buy). Pro unlocks once it's approved."
                return false
            case .userCancelled:
                return false
            @unknown default:
                return false
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            return false
        }
    }

    func restore() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if !isPro { errorMessage = "No active GoalStats Pro subscription found for this Apple ID." }
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Gating

/// Pro check usable from any code (not tied to the main actor). Reads the
/// entitlement StoreKit last confirmed, so Pro keeps working offline.
enum ProAccess {
    static let cacheKey = "pro_entitlement_cached"
    /// Debug builds only: Settings > Debug > "Simulate Pro".
    static let debugOverrideKey = "pro_debug_override"

    static var isPro: Bool {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: debugOverrideKey) { return true }
        #endif
        return UserDefaults.standard.bool(forKey: cacheKey)
    }
}

/// Shows the paywall over whatever is on screen (works from inside sheets too).
@MainActor
enum Paywall {
    /// True if the coach has Pro. Otherwise opens the paywall for `feature` and returns false.
    @discardableResult
    static func require(_ feature: ProFeature) -> Bool {
        if ProAccess.isPro { return true }
        show(feature)
        return false
    }

    static func show(_ feature: ProFeature? = nil) {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        guard let root = scene?.keyWindow?.rootViewController ?? scene?.windows.first?.rootViewController else { return }
        var top = root
        while let presented = top.presentedViewController { top = presented }
        if top is UIHostingController<PaywallView> { return } // already showing

        final class Holder { weak var controller: UIViewController? }
        let holder = Holder()
        let host = UIHostingController(rootView: PaywallView(highlight: feature, onClose: {
            holder.controller?.dismiss(animated: true)
        }))
        holder.controller = host
        Haptics.light()
        top.present(host, animated: true)
    }
}
