import SwiftUI
import PhotosUI

struct CreateTeamView: View {

    var teamStore: TeamStore
    var onCreated: (UUID) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var fieldSize: Int = 11
    @State private var primaryFormation: Formation = .f433
    @State private var players: [Player] = []
    @State private var showAddPlayer = false
    @State private var showAIImport = false

    private var sortedPlayers: [Player] {
        players.sorted { lhs, rhs in
            if lhs.number == rhs.number {
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            return lhs.number < rhs.number
        }
    }

    private var canCreate: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GoStatsTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // Team icon
                        ZStack {
                            Circle()
                                .fill(GoStatsTheme.textPrimary)
                                .frame(width: 72, height: 72)
                            Image(systemName: "soccerball")
                                .font(.system(size: 30, weight: .regular))
                                .foregroundStyle(.white)
                        }
                        .padding(.top, 8)

                        // Team info card
                        VStack(alignment: .leading, spacing: 16) {
                            fieldRow(label: "TEAM NAME", icon: "flag") {
                                TextField("Enter team name", text: $name)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(GoStatsTheme.textPrimary)
                            }

                            Divider()

                            fieldRow(label: "FIELD SIZE", icon: "sportscourt") {
                                Picker("", selection: $fieldSize) {
                                    Text("7v7").tag(7)
                                    Text("9v9").tag(9)
                                    Text("11v11").tag(11)
                                }
                                .pickerStyle(.segmented)
                            }

                            Divider()

                            fieldRow(label: "PRIMARY FORMATION", icon: "rectangle.3.group") {
                                Picker("", selection: $primaryFormation) {
                                    ForEach(Formation.allCases.filter { $0.playerCount == fieldSize }) { formation in
                                        Text(formation.rawValue).tag(formation)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(GoStatsTheme.textPrimary)
                                .onChange(of: fieldSize) { _, newSize in
                                    if primaryFormation.playerCount != newSize {
                                        primaryFormation = Formation.allCases.first(where: { $0.playerCount == newSize }) ?? primaryFormation
                                    }
                                }
                            }
                        }
                        .padding(GoStatsTheme.cardPadding)
                        .background(cardBackground)

                        // Players card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                fieldLabel("PLAYERS", icon: "person.3")
                                Spacer()
                                if !players.isEmpty {
                                    Text("\(players.count)")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Circle().fill(GoStatsTheme.textPrimary))
                                }
                            }

                            if sortedPlayers.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "person.badge.plus")
                                        .font(.system(size: 28))
                                        .foregroundStyle(GoStatsTheme.textMuted)
                                    Text("Add players to build your roster")
                                        .font(.system(size: 13))
                                        .foregroundStyle(GoStatsTheme.textMuted)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(Array(sortedPlayers.enumerated()), id: \.element.id) { index, player in
                                        if index > 0 {
                                            Divider()
                                        }
                                        HStack(spacing: 12) {
                                            ZStack {
                                                Circle()
                                                    .fill(GoStatsTheme.textPrimary)
                                                    .frame(width: 32, height: 32)
                                                Text("\(player.number)")
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundStyle(.white)
                                            }

                                            VStack(alignment: .leading, spacing: 1) {
                                                Text(player.name)
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundStyle(GoStatsTheme.textPrimary)
                                                Text(player.position.rawValue)
                                                    .font(.system(size: 11))
                                                    .foregroundStyle(GoStatsTheme.textMuted)
                                            }

                                            Spacer()

                                            Button {
                                                players.removeAll { $0.id == player.id }
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 16))
                                                    .foregroundStyle(GoStatsTheme.textMuted)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(.vertical, 8)
                                    }
                                }
                            }

                            // Add player buttons
                            HStack(spacing: 10) {
                                Button {
                                    showAddPlayer = true
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 12, weight: .semibold))
                                        Text("Add Player")
                                            .font(.system(size: 13, weight: .semibold))
                                    }
                                    .foregroundStyle(GoStatsTheme.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(GoStatsTheme.textPrimary, lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(.plain)

                                Button {
                                    if Paywall.require(.rosterImport) { showAIImport = true }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 12, weight: .semibold))
                                        Text("AI Import")
                                            .font(.system(size: 13, weight: .semibold))
                                    }
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(GoStatsTheme.textPrimary)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(GoStatsTheme.cardPadding)
                        .background(cardBackground)

                        // Create team button
                        Button {
                            create()
                        } label: {
                            Text("Create Team")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
                                        .fill(GoStatsTheme.textPrimary.opacity(canCreate ? 1.0 : 0.35))
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(!canCreate)

                        Button { dismiss() } label: {
                            Text("Cancel")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "aaaaaa"))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Create Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showAddPlayer) {
            CreatePlayerView { player in
                players.append(player)
            }
        }
        .sheet(isPresented: $showAIImport) {
            CreateTeamAIImportView { importedPlayers in
                players.append(contentsOf: importedPlayers)
            }
        }
    }

    // MARK: - Helpers

    private func fieldRow<Content: View>(label: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel(label, icon: icon)
            content()
        }
    }

    private func fieldLabel(_ label: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(GoStatsTheme.textMuted)
                .frame(width: 16)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(GoStatsTheme.textMuted)
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: GoStatsTheme.cardRadius, style: .continuous)
            .fill(Color.white)
            .shadow(color: GoStatsTheme.cardShadowColor,
                    radius: GoStatsTheme.cardShadowRadius,
                    x: 0, y: GoStatsTheme.cardShadowY)
    }

    private func create() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let starterIDs = sortedPlayers.prefix(fieldSize).map(\.id)
        let goalkeeperDepth = Team.goalkeeperDepthIDs(from: sortedPlayers)
        let team = Team(
            id: UUID(),
            name: trimmed,
            players: sortedPlayers,
            fieldSize: fieldSize,
            startingOnFieldIDs: starterIDs,
            primaryFormation: primaryFormation,
            primaryGoalkeeperID: goalkeeperDepth.primary,
            secondaryGoalkeeperID: goalkeeperDepth.secondary,
            thirdGoalkeeperID: goalkeeperDepth.third,
            matches: []
        )

        teamStore.addTeam(team)
        onCreated(team.id)
        dismiss()
    }
}

// MARK: - AI Import for Create Team (returns players, doesn't save to store)

private struct CreateTeamAIImportView: View {
    let onImport: ([Player]) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var phase: Phase = .picking
    @State private var importedPlayers: [ImportedPlayer] = []
    @State private var errorMessage: String? = nil
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var showDocumentPicker = false

    private enum Phase { case picking, loading, review }

    var body: some View {
        NavigationStack {
            ZStack {
                GoStatsTheme.bg.ignoresSafeArea()

                switch phase {
                case .picking:
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

                case .loading:
                    VStack(spacing: 16) {
                        ProgressView()
                            .controlSize(.large)
                        Text("Reading your roster...")
                            .font(.system(size: 15))
                            .foregroundStyle(GoStatsTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

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
            .alert("Couldn't read this file", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil; phase = .picking } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Try a clearer image or a different file.")
            }
            .sheet(isPresented: $showDocumentPicker) {
                CreateTeamDocPicker { data, mediaType in
                    processFileData(data, mediaType: mediaType)
                }
            }
        }
    }

    private var reviewScreen: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    Text("\(importedPlayers.count) players found")
                        .font(.system(size: 13))
                        .foregroundStyle(GoStatsTheme.textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(0..<importedPlayers.count, id: \.self) { i in
                        HStack(spacing: 12) {
                            TextField("#", text: Binding(
                                get: { importedPlayers[i].number.map { "\($0)" } ?? "" },
                                set: { importedPlayers[i].number = Int($0) }
                            ))
                            .keyboardType(.numberPad)
                            .font(.system(size: 15, weight: .bold))
                            .frame(width: 40)
                            .multilineTextAlignment(.center)

                            TextField("Name", text: $importedPlayers[i].name)
                                .font(.system(size: 14, weight: .medium))

                            Picker("", selection: $importedPlayers[i].position) {
                                Text("--").tag(nil as Position?)
                                ForEach(Position.rosterPositions) { pos in
                                    Text(pos.rawValue).tag(Optional(pos))
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(GoStatsTheme.textPrimary)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(importedPlayers[i].position == nil ? Color(hex: "FFFBEB") : Color.white)
                                .shadow(color: GoStatsTheme.cardShadowColor, radius: 2, x: 0, y: 1)
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }

            Button {
                let converted = importedPlayers.map { imp in
                    Player(
                        name: imp.name,
                        number: imp.number ?? 0,
                        position: imp.position ?? .cm
                    )
                }
                onImport(converted)
                dismiss()
            } label: {
                Text("Add All Players")
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
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    private func processPhoto(_ item: PhotosPickerItem) {
        phase = .loading
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self) else {
                await MainActor.run { errorMessage = "Couldn't read this file. Try a clearer image or a different file." }
                return
            }
            await callAPI(base64: data.base64EncodedString(), mediaType: "image/jpeg")
        }
    }

    private func processFileData(_ data: Data, mediaType: String) {
        phase = .loading
        Task {
            await callAPI(base64: data.base64EncodedString(), mediaType: mediaType)
        }
    }

    private func callAPI(base64: String, mediaType: String) async {
        let apiKey = UserDefaults.standard.string(forKey: "anthropic_api_key") ?? ""
        guard !apiKey.isEmpty else {
            await MainActor.run { errorMessage = "Add your Anthropic API key in Settings." }
            return
        }

        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")

        let sourceType = mediaType == "application/pdf" ? "document" : "image"
        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 1000,
            "system": "You are a sports roster reader. Extract all players from this image or document. For each player return a JSON array with these exact fields: \"name\" (full name), \"number\" (jersey number as integer or null if not found), \"position\" (position abbreviation like GK, CB, RB, LB, CM, CDM, CAM, RM, LM, ST, CF or null if not found). Return ONLY the JSON array, no other text, no markdown, no backticks.",
            "messages": [[
                "role": "user",
                "content": [
                    ["type": sourceType, "source": ["type": "base64", "media_type": mediaType, "data": base64]],
                    ["type": "text", "text": "Extract the roster from this image."]
                ]
            ]]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (responseData, _) = try await URLSession.shared.data(for: request)
            guard let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
                  let content = json["content"] as? [[String: Any]],
                  let text = content.first?["text"] as? String,
                  let jsonData = text.data(using: .utf8),
                  let parsed = try? JSONDecoder().decode([RawPlayerData].self, from: jsonData)
            else {
                await MainActor.run { errorMessage = "Couldn't read this file. Try a clearer image or a different file." }
                return
            }

            let result = parsed.map { raw in
                ImportedPlayer(name: raw.name, number: raw.number, position: raw.position.flatMap { Position(rawValue: $0) })
            }
            await MainActor.run {
                importedPlayers = result
                phase = .review
            }
        } catch {
            await MainActor.run { errorMessage = "Couldn't read this file. Try a clearer image or a different file." }
        }
    }

    private struct RawPlayerData: Codable {
        let name: String
        let number: Int?
        let position: String?
    }
}

// MARK: - Document Picker for Create Team AI Import

private struct CreateTeamDocPicker: UIViewControllerRepresentable {
    let onPick: (Data, String) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [.image, .jpeg, .png, .pdf]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (Data, String) -> Void
        init(onPick: @escaping (Data, String) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            guard let data = try? Data(contentsOf: url) else { return }
            let ext = url.pathExtension.lowercased()
            let mediaType: String
            switch ext {
            case "pdf": mediaType = "application/pdf"
            case "png": mediaType = "image/png"
            default: mediaType = "image/jpeg"
            }
            onPick(data, mediaType)
        }
    }
}
