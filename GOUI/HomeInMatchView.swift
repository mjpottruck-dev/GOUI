import SwiftUI

struct HomeInMatchView: View {

    @ObservedObject var store: MatchStore
    var teamStore: TeamStore
    let selectedTeamID: UUID
    let onExitToHome: () -> Void

    var body: some View {
        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {

                    LiquidGlassContainer(cornerRadius: 22) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(teamName)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(GoStatsTheme.text)

                                Text("Ready to track your match")
                                    .font(.system(size: 14))
                                    .foregroundStyle(GoStatsTheme.text2)
                            }

                            Spacer()

                            Button {
                                onExitToHome()
                            } label: {
                                Text("Exit")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.red)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.6))
                                    )
                            }
                        }
                    }

                    LiquidGlassContainer(cornerRadius: 22) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CURRENT FORMATION")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(GoStatsTheme.text2)

                            Text(store.formation?.rawValue ?? "Not set")
                                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                                .foregroundStyle(GoStatsTheme.text)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var teamName: String {
        teamStore.teams.first(where: { $0.id == selectedTeamID })?.name ?? "Team"
    }
}

