import SwiftUI
import CoreLocation

struct EndMatchSheet: View {

    @ObservedObject var store: MatchStore
    let teamStore: TeamStore
    let teamID: UUID
    let team: Team
    let formation: Formation
    var onMatchSaved: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationHelper()

    @State private var opponent: String = ""
    @State private var venue: String = ""
    @State private var showOpponentError = false
    @State private var savedRecord: MatchRecord? = nil
    @State private var showExportSheet = false

    private var canSave: Bool {
        !opponent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "f5f5f5").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: GoStatsTheme.cardGap) {

                        // Summary card
                        VStack(spacing: 12) {
                            GoStatsTheme.sectionHeader("SUMMARY")
                                .frame(maxWidth: .infinity, alignment: .leading)

                            HStack {
                                Text("Score")
                                    .font(.system(size: 15))
                                    .foregroundStyle(GoStatsTheme.textPrimary)
                                Spacer()
                                Text("\(store.goalsFor) - \(store.goalsAgainst)")
                                    .font(.system(size: 15, weight: .semibold))
                                    .monospacedDigit()
                                    .foregroundStyle(GoStatsTheme.textMuted)
                            }

                            Rectangle().fill(GoStatsTheme.divider).frame(height: GoStatsTheme.dividerWidth)

                            HStack {
                                Text("Time")
                                    .font(.system(size: 15))
                                    .foregroundStyle(GoStatsTheme.textPrimary)
                                Spacer()
                                Text(store.timeString)
                                    .font(.system(size: 15, weight: .semibold))
                                    .monospacedDigit()
                                    .foregroundStyle(GoStatsTheme.textMuted)
                            }
                        }
                        .padding(GoStatsTheme.cardPadding)
                        .background(
                            RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                                .fill(Color.white)
                                .shadow(color: GoStatsTheme.cardShadowColor,
                                        radius: GoStatsTheme.cardShadowRadius,
                                        x: 0, y: GoStatsTheme.cardShadowY)
                        )

                        // Opponent card
                        VStack(alignment: .leading, spacing: 12) {
                            GoStatsTheme.sectionHeader("OPPONENT")

                            TextField("Opponent name", text: $opponent)
                                .font(.system(size: 15))
                                .foregroundStyle(GoStatsTheme.textPrimary)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                                .onChange(of: opponent) { _, _ in
                                    if showOpponentError && !opponent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        showOpponentError = false
                                    }
                                }

                            if showOpponentError {
                                Text("Opponent name is required")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.red)
                            }
                        }
                        .padding(GoStatsTheme.cardPadding)
                        .background(
                            RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                                .fill(Color.white)
                                .shadow(color: GoStatsTheme.cardShadowColor,
                                        radius: GoStatsTheme.cardShadowRadius,
                                        x: 0, y: GoStatsTheme.cardShadowY)
                        )

                        // Location card
                        VStack(alignment: .leading, spacing: 12) {
                            GoStatsTheme.sectionHeader("LOCATION")

                            HStack(spacing: 12) {
                                Button {
                                    locationManager.requestLocation { address in
                                        if let address { venue = address }
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        if locationManager.isLoading {
                                            ProgressView().controlSize(.small)
                                        } else {
                                            Image(systemName: "location.fill")
                                                .font(.system(size: 12))
                                        }
                                        Text("Current Location")
                                            .font(.system(size: 13, weight: .medium))
                                    }
                                    .foregroundStyle(GoStatsTheme.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(Color(hex: "f0f0f0"))
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(locationManager.isLoading)

                                Spacer()
                            }

                            Rectangle().fill(GoStatsTheme.divider).frame(height: GoStatsTheme.dividerWidth)

                            TextField("Or type location", text: $venue)
                                .font(.system(size: 15))
                                .foregroundStyle(GoStatsTheme.textPrimary)
                                .textInputAutocapitalization(.words)
                        }
                        .padding(GoStatsTheme.cardPadding)
                        .background(
                            RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                                .fill(Color.white)
                                .shadow(color: GoStatsTheme.cardShadowColor,
                                        radius: GoStatsTheme.cardShadowRadius,
                                        x: 0, y: GoStatsTheme.cardShadowY)
                        )

                        // Save button
                        Button { attemptSave() } label: {
                            Text("Save Match")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                                        .fill(GoStatsTheme.textPrimary)
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)

                        // Discard — small muted text link
                        Button {
                            store.resetForNewMatch(team: team, formation: formation, seasonID: teamStore.activeSeasonID)
                            dismiss()
                        } label: {
                            Text("Discard Match")
                                .font(.system(size: 12))
                                .foregroundStyle(GoStatsTheme.textMuted)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, GoStatsTheme.cardMargin)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("End Match")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showExportSheet) {
            if let record = savedRecord {
                PostMatchExportSheet(
                    match: record,
                    team: team,
                    players: store.players,
                    onDone: {
                        dismiss()
                        onMatchSaved?()
                    }
                )
            }
        }
    }

    private func attemptSave() {
        guard canSave else {
            showOpponentError = true
            return
        }
        let record = store.buildMatchRecord(
            opponent: opponent,
            title: "",
            notes: "",
            venue: venue
        )
        teamStore.addMatchRecord(teamID: teamID, record: record)
        savedRecord = record

        // Analyze substitution patterns from this match
        SubstitutionPatternStore.shared.analyzeMatch(record, teamPlayers: team.players)

        store.resetForNewMatch(team: team, formation: formation, seasonID: teamStore.activeSeasonID)
        showExportSheet = true
    }
}

// MARK: - Location Helper

private final class LocationHelper: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var isLoading = false
    private let manager = CLLocationManager()
    private var completion: ((String?) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestLocation(completion: @escaping (String?) -> Void) {
        self.completion = completion
        isLoading = true

        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            isLoading = false
            completion(nil)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            if isLoading { manager.requestLocation() }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            isLoading = false
            completion?(nil)
            return
        }
        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let pm = placemarks?.first {
                    let parts = [pm.name, pm.locality, pm.administrativeArea].compactMap { $0 }
                    self?.completion?(parts.joined(separator: ", "))
                } else {
                    self?.completion?(nil)
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLoading = false
        completion?(nil)
    }
}
