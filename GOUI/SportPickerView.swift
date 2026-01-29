import SwiftUI

struct SportPickerView: View {
    @Binding var selectedSportID: String
    @Environment(\.dismiss) private var dismiss

    private let fallSports = SportCatalog.all.filter { $0.season == .fall }
    private let winterSports = SportCatalog.all.filter { $0.season == .winter }
    private let springSports = SportCatalog.all.filter { $0.season == .spring }

    var body: some View {
        List {
            sportSection(title: "Fall", sports: fallSports)
            sportSection(title: "Winter", sports: winterSports)
            sportSection(title: "Spring", sports: springSports)
            sportSection(title: "All Sports", sports: SportCatalog.all)
        }
        .navigationTitle("Pick Sport")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sportSection(title: String, sports: [any SportDefinition]) -> some View {
        Section(title) {
            ForEach(sports, id: \.id) { sport in
                Button {
                    selectedSportID = sport.id
                    dismiss()
                } label: {
                    HStack {
                        Text(sport.displayName)
                        Spacer()
                        if selectedSportID == sport.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(GoStatsTheme.primary)
                        }
                    }
                }
            }
        }
    }
}
