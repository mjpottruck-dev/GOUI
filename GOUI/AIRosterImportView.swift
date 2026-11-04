import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct AIRosterImportView: View {
    let teamStore: TeamStore
    let teamID: UUID
    @Environment(\.dismiss) private var dismiss

    @State private var phase: Phase = .picking
    @State private var importedPlayers: [ImportedPlayer] = []
    @State private var missingCount = 0
    @State private var requireAllPositions = false
    @State private var errorMessage: String? = nil
    @State private var showMissingAlert = false
    @State private var showConflict = false
    @State private var conflictPlayer: ImportedPlayer? = nil
    @State private var toastMessage: String? = nil
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var showDocumentPicker = false
    @State private var remainingPlayers: [ImportedPlayer] = []
    @State private var importedCount = 0

    private enum Phase { case picking, loading, review }

    private var team: Team? {
        teamStore.teams.first(where: { $0.id == teamID })
    }

    private var allPositionsFilled: Bool {
        importedPlayers.allSatisfy { $0.position != nil }
    }

    private var importAllDisabled: Bool {
        requireAllPositions && !allPositionsFilled
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GoStatsTheme.bg.ignoresSafeArea()

                switch phase {
                case .picking:
                    pickerScreen

                case .loading:
                    VStack(spacing: 16) {
                        ProgressView()
                            .controlSize(.large)
                        Text("Reading your roster...")
                            .font(.system(size: 15))
                            .foregroundStyle(GoStatsTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(GoStatsTheme.bg)

                case .review:
                    reviewScreen
                }
            }
            .navigationTitle("Import Roster via AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                guard let item = newValue else { return }
                processPhoto(item)
            }
            .alert("Some positions are missing", isPresented: $showMissingAlert) {
                Button("Add Now") {
                    requireAllPositions = true
                    phase = .review
                }
                Button("Add Later") {
                    requireAllPositions = false
                    phase = .review
                }
            } message: {
                Text("AI could not detect positions for \(missingCount) players. Add them now or later?")
            }
            .alert("Couldn't read this file", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil; phase = .picking } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Try a clearer image or a different file.")
            }
            .alert("Player #\(conflictPlayer?.number ?? 0) already exists. Replace or skip?", isPresented: $showConflict) {
                Button("Replace") { resolveConflict(replace: true) }
                Button("Skip") { resolveConflict(replace: false) }
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPickerView { data, mediaType in
                    processFileData(data, mediaType: mediaType)
                }
            }
            .overlay(alignment: .bottom) {
                if let toast = toastMessage {
                    Text(toast)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color(hex: "1a1a1a")))
                        .padding(.bottom, 40)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - Picker Screen

    private var pickerScreen: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.viewfinder")
                .font(.system(size: 48))
                .foregroundStyle(GoStatsTheme.textMuted)
            Text("Select a photo or file of your roster")
                .font(.system(size: 15))
                .foregroundStyle(GoStatsTheme.textMuted)

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Text("Choose Photo")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                            .fill(Color(hex: "1a1a1a"))
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 40)

            Button {
                showDocumentPicker = true
            } label: {
                Text("Choose File")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: "1a1a1a"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                            .stroke(Color(hex: "1a1a1a"), lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Review Screen

    private var reviewScreen: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: GoStatsTheme.cardGap) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Review Imported Players")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(GoStatsTheme.textPrimary)
                        Text("\(importedPlayers.count) players found \u{2014} edit before importing")
                            .font(.system(size: 13))
                            .foregroundStyle(GoStatsTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(0..<importedPlayers.count, id: \.self) { i in
                        playerEditCard(index: i)
                    }
                }
                .padding(.horizontal, GoStatsTheme.cardMargin)
                .padding(.top, 16)
                .padding(.bottom, 16)
            }

            VStack(spacing: 8) {
                Button { importAll() } label: {
                    Text("Import All")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                                .fill(Color(hex: "1a1a1a").opacity(importAllDisabled ? 0.4 : 1.0))
                        )
                }
                .buttonStyle(.plain)
                .disabled(importAllDisabled)

                Button { dismiss() } label: {
                    Text("Cancel")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "aaaaaa"))
                }
                .buttonStyle(.plain)
                .padding(.bottom, 8)
            }
            .padding(.horizontal, GoStatsTheme.cardMargin)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
    }

    private func playerEditCard(index: Int) -> some View {
        let hasMissingPos = importedPlayers[index].position == nil
        return VStack(spacing: 10) {
            HStack(spacing: 12) {
                TextField("#", text: Binding(
                    get: { importedPlayers[index].number.map { "\($0)" } ?? "" },
                    set: { importedPlayers[index].number = Int($0) }
                ))
                .keyboardType(.numberPad)
                .font(.system(size: 16, weight: .bold))
                .frame(width: 44)
                .multilineTextAlignment(.center)

                TextField("Player name", text: $importedPlayers[index].name)
                    .font(.system(size: 15, weight: .medium))

                Picker("Pos", selection: $importedPlayers[index].position) {
                    Text("--").tag(nil as Position?)
                    ForEach(Position.rosterPositions) { pos in
                        Text(pos.rawValue).tag(Optional(pos))
                    }
                }
                .pickerStyle(.menu)
                .tint(hasMissingPos ? Color(hex: "aaaaaa") : GoStatsTheme.textPrimary)
            }

            if hasMissingPos {
                Text("Tap to add position")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "aaaaaa"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(GoStatsTheme.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                .fill(hasMissingPos ? Color(hex: "FFFBEB") : Color.white)
                .shadow(color: GoStatsTheme.cardShadowColor, radius: GoStatsTheme.cardShadowRadius, x: 0, y: GoStatsTheme.cardShadowY)
        )
    }

    // MARK: - Process Photo

    private func processPhoto(_ item: PhotosPickerItem) {
        phase = .loading
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self) else {
                await MainActor.run {
                    errorMessage = "Couldn't read this file. Try a clearer image or a different file."
                }
                return
            }
            await processImageData(data)
        }
    }

    // MARK: - Process File Data

    private func processFileData(_ data: Data, mediaType: String) {
        phase = .loading
        Task {
            if mediaType == "application/pdf" {
                await callAnthropicAPI(base64: data.base64EncodedString(), mediaType: "application/pdf")
            } else {
                await processImageData(data)
            }
        }
    }

    private func processImageData(_ data: Data) async {
        if data.count > 10_000_000 {
            await MainActor.run {
                errorMessage = "File too large. Try a smaller image."
            }
            return
        }
        await callAnthropicAPI(base64: data.base64EncodedString(), mediaType: "image/jpeg")
    }

    private func callAnthropicAPI(base64: String, mediaType: String) async {
        do {
            let players = try await callAnthropicVision(base64Data: base64, mediaType: mediaType)
            await MainActor.run {
                importedPlayers = players
                missingCount = players.filter { $0.position == nil }.count
                if missingCount > 0 {
                    showMissingAlert = true
                } else {
                    phase = .review
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Couldn't read this file. Try a clearer image or a different file."
            }
        }
    }

    private func callAnthropicVision(base64Data: String, mediaType: String) async throws -> [ImportedPlayer] {
        let apiKey = UserDefaults.standard.string(forKey: "anthropic_api_key") ?? ""
        guard !apiKey.isEmpty else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Add your Anthropic API key in Settings."])
        }

        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")

        let systemPrompt = "You are a sports roster reader. Extract all players from this image or document. For each player return a JSON array with these exact fields: \"name\" (full name), \"number\" (jersey number as integer or null if not found), \"position\" (position abbreviation like GK, CB, RB, LB, CM, CDM, CAM, RM, LM, ST, CF or null if not found). Return ONLY the JSON array, no other text, no markdown, no backticks."

        let sourceType: String
        if mediaType == "application/pdf" {
            sourceType = "document"
        } else {
            sourceType = "image"
        }

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 1000,
            "system": systemPrompt,
            "messages": [[
                "role": "user",
                "content": [
                    [
                        "type": sourceType,
                        "source": [
                            "type": "base64",
                            "media_type": mediaType,
                            "data": base64Data
                        ]
                    ],
                    [
                        "type": "text",
                        "text": "Extract the roster from this image."
                    ]
                ]
            ]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (responseData, _) = try await URLSession.shared.data(for: request)

        guard let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let text = content.first?["text"] as? String,
              let jsonData = text.data(using: .utf8),
              let parsed = try? JSONDecoder().decode([RawPlayer].self, from: jsonData)
        else {
            throw NSError(domain: "", code: 0)
        }

        return parsed.map { raw in
            ImportedPlayer(
                name: raw.name,
                number: raw.number,
                position: raw.position.flatMap { Position(rawValue: $0) }
            )
        }
    }

    // MARK: - Import

    private func importAll() {
        guard let team else { return }
        remainingPlayers = importedPlayers
        importedCount = 0
        processNextImport(team: team)
    }

    private func processNextImport(team: Team) {
        guard let currentTeam = self.team else {
            finishImport()
            return
        }

        while !remainingPlayers.isEmpty {
            let player = remainingPlayers.removeFirst()
            let number = player.number ?? ((currentTeam.players.map(\.number).max() ?? 0) + 1)
            if currentTeam.players.contains(where: { $0.number == number }) {
                conflictPlayer = player
                showConflict = true
                return
            }
            let newPlayer = Player(
                name: player.name,
                number: number,
                position: player.position ?? .cm
            )
            teamStore.addPlayer(newPlayer, to: teamID)
            importedCount += 1
        }

        finishImport()
    }

    private func resolveConflict(replace: Bool) {
        guard let cp = conflictPlayer else { return }
        if replace, let number = cp.number {
            if let existingIdx = team?.players.firstIndex(where: { $0.number == number }) {
                var updated = team!.players[existingIdx]
                updated.name = cp.name
                updated.position = cp.position ?? updated.position
                teamStore.updatePlayer(updated, on: teamID)
                importedCount += 1
            }
        }
        conflictPlayer = nil
        if let team = self.team {
            processNextImport(team: team)
        }
    }

    private func finishImport() {
        showToast("\(importedCount) players imported successfully")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
    }

    private func showToast(_ message: String) {
        withAnimation { toastMessage = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { toastMessage = nil }
        }
    }
}

// MARK: - Data Models

struct ImportedPlayer: Identifiable {
    let id = UUID()
    var name: String
    var number: Int?
    var position: Position?
}

private struct RawPlayer: Codable {
    let name: String
    let number: Int?
    let position: String?
}

// MARK: - Document Picker

private struct DocumentPickerView: UIViewControllerRepresentable {
    let onPick: (Data, String) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [.image, .jpeg, .png, .pdf]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (Data, String) -> Void

        init(onPick: @escaping (Data, String) -> Void) {
            self.onPick = onPick
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }

            guard let data = try? Data(contentsOf: url) else { return }
            let ext = url.pathExtension.lowercased()
            let mediaType: String
            switch ext {
            case "pdf":
                mediaType = "application/pdf"
            case "png":
                mediaType = "image/png"
            default:
                mediaType = "image/jpeg"
            }
            onPick(data, mediaType)
        }
    }
}
