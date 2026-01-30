import AVFoundation
import AVKit
import Photos
import SwiftUI

struct HighlightsHubView: View {
    enum Mode: String, CaseIterable {
        case game = "Game"
        case player = "Player"
    }

    @ObservedObject var matchStore: MatchStore
    @ObservedObject var clipStore: ClipStore
    @Bindable var teamStore: TeamStore
    let teamID: UUID

    @State private var mode: Mode = .game
    @State private var selectedGameID: UUID? = nil

    var body: some View {
        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    modePicker

                    if mode == .game {
                        gameHighlights
                    } else {
                        playerHighlights
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }
        }
        .navigationTitle("Highlights")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if selectedGameID == nil {
                selectedGameID = matchStore.currentMatchID
            }
        }
    }

    private var modePicker: some View {
        LiquidGlassContainer {
            Picker("Highlights Mode", selection: $mode) {
                ForEach(Mode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var gameHighlights: some View {
        VStack(spacing: 12) {
            LiquidGlassContainer(cornerRadius: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("GAME")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.primary)

                    Picker("Game", selection: $selectedGameID) {
                        ForEach(gameSelections) { selection in
                            Text(selection.label).tag(Optional(selection.id))
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            if let selectedGameID {
                GameHighlightsView(
                    gameID: selectedGameID,
                    teamStore: teamStore,
                    teamID: teamID,
                    clipStore: clipStore
                )
            }
        }
    }

    private var playerHighlights: some View {
        PlayerHighlightsView(teamStore: teamStore, teamID: teamID, clipStore: clipStore)
    }

    private var gameSelections: [GameSelection] {
        guard let team = teamStore.teams.first(where: { $0.id == teamID }) else { return [] }
        var selections: [GameSelection] = [
            GameSelection(id: matchStore.currentMatchID, label: "Current Match")
        ]
        for match in team.matches {
            let title = match.title.isEmpty ? (match.opponent.isEmpty ? "Match" : match.opponent) : match.title
            let label = "\(title) • \(match.date.formatted(date: .abbreviated, time: .shortened))"
            selections.append(GameSelection(id: match.id, label: label))
        }
        return selections
    }

    private struct GameSelection: Identifiable {
        let id: UUID
        let label: String
    }
}

struct GameHighlightsView: View {
    let gameID: UUID
    @Bindable var teamStore: TeamStore
    let teamID: UUID
    @ObservedObject var clipStore: ClipStore
    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(spacing: 12) {
            ClipListView(
                title: "GAME HIGHLIGHTS",
                clips: clipStore.clips(for: gameID),
                clipStore: clipStore,
                teamStore: teamStore,
                teamID: teamID
            )

            LiquidGlassContainer(cornerRadius: 22) {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "trash")
                        Text("Delete all video for this game")
                            .font(.system(size: 15, weight: .semibold))
                        Spacer()
                    }
                    .foregroundStyle(.red)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
        .confirmationDialog("Delete all video for this game?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete All Video", role: .destructive) {
                clipStore.deleteAllVideo(for: gameID)
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct PlayerHighlightsView: View {
    @Bindable var teamStore: TeamStore
    let teamID: UUID
    @ObservedObject var clipStore: ClipStore

    @State private var selectedPlayerID: UUID? = nil
    @State private var selectedSeasonID: UUID? = nil

    private var team: Team? {
        teamStore.teams.first(where: { $0.id == teamID })
    }

    private var seasons: [Season] {
        teamStore.seasons(for: teamID)
    }

    var body: some View {
        VStack(spacing: 12) {
            LiquidGlassContainer(cornerRadius: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("PLAYER")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.primary)

                    Picker("Player", selection: $selectedPlayerID) {
                        Text("Select Player").tag(Optional<UUID>.none)
                        if let team {
                            ForEach(team.players) { player in
                                Text("#\(player.number) \(player.name)").tag(Optional(player.id))
                            }
                        }
                    }
                    .pickerStyle(.menu)

                    if !seasons.isEmpty {
                        Picker("Season", selection: $selectedSeasonID) {
                            Text("All Seasons").tag(Optional<UUID>.none)
                            ForEach(seasons) { season in
                                Text(season.name).tag(Optional(season.id))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }

            if let selectedPlayerID {
                let clips = filteredPlayerClips(playerID: selectedPlayerID)
                ClipListView(
                    title: "PLAYER HIGHLIGHTS",
                    clips: clips,
                    clipStore: clipStore,
                    teamStore: teamStore,
                    teamID: teamID
                )
            } else {
                LiquidGlassContainer(cornerRadius: 22) {
                    HStack(spacing: 10) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(GoStatsTheme.text2)
                        Text("Pick a player to see highlights.")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(GoStatsTheme.text2)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .onAppear {
            if selectedSeasonID == nil {
                selectedSeasonID = teamStore.activeSeasonID(for: teamID)
            }
        }
    }

    private func filteredPlayerClips(playerID: UUID) -> [Clip] {
        let clips = clipStore.clips(for: playerID)
        guard let seasonID = selectedSeasonID else { return clips }
        let matches = teamStore.teams.first(where: { $0.id == teamID })?.matches ?? []
        let matchIDs = matches.filter { $0.seasonID == seasonID }.map { $0.id }
        return clips.filter { matchIDs.contains($0.gameID) }
    }
}

struct ClipListView: View {
    let title: String
    let clips: [Clip]
    @ObservedObject var clipStore: ClipStore
    let teamStore: TeamStore
    let teamID: UUID

    @State private var selectedClip: Clip? = nil

    var body: some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.primary)

                if clips.isEmpty {
                    Text("No clips yet.")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text2)
                } else {
                    VStack(spacing: 10) {
                        ForEach(clips.sorted(by: { $0.createdAt > $1.createdAt })) { clip in
                            Button {
                                selectedClip = clip
                            } label: {
                                ClipRowView(
                                    clip: clip,
                                    recording: clipStore.recording(for: clip.recordingID),
                                    playerNames: playerNames(for: clip.linkedPlayerIDs)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedClip) { clip in
            ClipDetailSheet(
                clip: clip,
                recording: clipStore.recording(for: clip.recordingID),
                playerNames: playerNames(for: clip.linkedPlayerIDs)
            )
        }
    }

    private func playerNames(for ids: [UUID]) -> [String] {
        guard let team = teamStore.teams.first(where: { $0.id == teamID }) else { return [] }
        return ids.compactMap { id in
            team.players.first(where: { $0.id == id })?.name
        }
    }
}

struct ClipRowView: View {
    let clip: Clip
    let recording: VideoRecording?
    let playerNames: [String]

    var body: some View {
        HStack(spacing: 12) {
            ClipThumbnailView(clip: clip, recording: recording)
                .frame(width: 72, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(clip.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text)

                if !playerNames.isEmpty {
                    Text(playerNames.joined(separator: ", "))
                        .font(.system(size: 12))
                        .foregroundStyle(GoStatsTheme.text2)
                }

                Text("Clip • \(clipDurationString)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text2)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.45))
        )
    }

    private var clipDurationString: String {
        let duration = max(0, clip.endOffset - clip.startOffset)
        return String(format: "%.1fs", duration)
    }
}

struct ClipThumbnailView: View {
    let clip: Clip
    let recording: VideoRecording?

    @State private var image: UIImage? = nil

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Rectangle()
                        .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.65))
                    Image(systemName: "video")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(GoStatsTheme.text2)
                }
            }
        }
        .task(id: clip.id) {
            guard let recording else { return }
            ThumbnailService.shared.thumbnail(for: clip, recording: recording) { image in
                self.image = image
            }
        }
    }
}

struct ClipDetailSheet: View {
    let clip: Clip
    let recording: VideoRecording?
    let playerNames: [String]

    @State private var shareSheetPayload: ShareSheetPayload? = nil
    @State private var exportError: String? = nil
    @State private var isExporting = false

    private let exportService = ClipExportService()
    private let uploadService: UploadClipService = StubUploadClipService()

    var body: some View {
        NavigationStack {
            ZStack {
                GoStatsTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        if let recording {
                            ClipPlayerView(clip: clip, recording: recording)
                                .frame(height: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        } else {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.65))
                                .frame(height: 220)
                                .overlay(
                                    Text("Video unavailable")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(GoStatsTheme.text2)
                                )
                        }

                        LiquidGlassContainer(cornerRadius: 22) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("CLIP")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(GoStatsTheme.primary)

                                Text(clip.title)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(GoStatsTheme.text)

                                if !playerNames.isEmpty {
                                    Text(playerNames.joined(separator: ", "))
                                        .font(.system(size: 13))
                                        .foregroundStyle(GoStatsTheme.text2)
                                }

                                Text("Created \(clip.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(GoStatsTheme.text2)
                            }
                        }

                        LiquidGlassContainer(cornerRadius: 22) {
                            VStack(spacing: 10) {
                                Button(action: exportAndShare) {
                                    Label("Share Clip", systemImage: "square.and.arrow.up")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(GoStatsTheme.text)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .disabled(isExporting)

                                Button(action: saveToPhotos) {
                                    Label("Save to Photos", systemImage: "photo")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(GoStatsTheme.text)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .disabled(isExporting)

                                Button(action: createShareLink) {
                                    Label("Create Share Link (Coming Soon)", systemImage: "link")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(GoStatsTheme.text)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .disabled(isExporting)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Clip")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(item: $shareSheetPayload) { payload in
            ShareSheet(activityItems: payload.items)
        }
        .alert("Export Failed", isPresented: Binding(get: { exportError != nil }, set: { _ in exportError = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportError ?? "")
        }
    }

    private func exportAndShare() {
        guard let recording else {
            exportError = "Recording missing."
            return
        }
        isExporting = true
        exportService.exportClip(clip: clip, recording: recording) { result in
            isExporting = false
            switch result {
            case .success(let url):
                shareSheetPayload = ShareSheetPayload(items: [url])
            case .failure(let error):
                exportError = error.localizedDescription
            }
        }
    }

    private func saveToPhotos() {
        guard let recording else {
            exportError = "Recording missing."
            return
        }
        isExporting = true
        exportService.exportClip(clip: clip, recording: recording) { result in
            switch result {
            case .success(let url):
                PHPhotoLibrary.requestAuthorization { status in
                    guard status == .authorized || status == .limited else {
                        DispatchQueue.main.async {
                            exportError = "Photo library access denied."
                            isExporting = false
                        }
                        return
                    }
                    PHPhotoLibrary.shared().performChanges {
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                    } completionHandler: { success, error in
                        DispatchQueue.main.async {
                            isExporting = false
                            if let error {
                                exportError = error.localizedDescription
                            } else if !success {
                                exportError = "Unable to save clip."
                            }
                        }
                    }
                }
            case .failure(let error):
                isExporting = false
                exportError = error.localizedDescription
            }
        }
    }

    private func createShareLink() {
        guard let recording else {
            exportError = "Recording missing."
            return
        }
        isExporting = true
        exportService.exportClip(clip: clip, recording: recording) { result in
            switch result {
            case .success(let url):
                uploadService.uploadClip(fileURL: url) { result in
                    DispatchQueue.main.async {
                        isExporting = false
                        if case .failure = result {
                            exportError = "Share links are coming soon."
                        }
                    }
                }
            case .failure(let error):
                isExporting = false
                exportError = error.localizedDescription
            }
        }
    }

    private struct ShareSheetPayload: Identifiable {
        let id = UUID()
        let items: [Any]
    }
}

struct ClipPlayerView: View {
    let clip: Clip
    let recording: VideoRecording

    @State private var player = AVPlayer()

    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                let item = AVPlayerItem(url: recording.fileURL)
                item.forwardPlaybackEndTime = CMTime(seconds: clip.endOffset, preferredTimescale: 600)
                player.replaceCurrentItem(with: item)
                player.seek(to: CMTime(seconds: clip.startOffset, preferredTimescale: 600))
            }
            .onDisappear {
                player.pause()
                player.replaceCurrentItem(with: nil)
            }
    }
}
