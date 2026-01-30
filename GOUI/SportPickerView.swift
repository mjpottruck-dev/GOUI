import SwiftUI

struct SportPickerView: View {
    @Binding var selectedSportID: String
    @Environment(\.dismiss) private var dismiss

    private let allSports = SportCatalog.all

    var body: some View {
        List {
            sportList(sports: allSports)
        }
        .navigationTitle("Pick Sport")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sportList(sports: [any SportDefinition]) -> some View {
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
