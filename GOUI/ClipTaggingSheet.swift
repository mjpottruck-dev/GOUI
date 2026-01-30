import SwiftUI

struct ClipTaggingSheet: View {
    @ObservedObject var clipStore: ClipStore
    let event: MatchEvent
    let gameID: UUID
    let players: [Player]
    let periodLabel: String
    let activeRecordingElapsed: TimeInterval?

    @Environment(\.dismiss) private var dismiss

    @State private var selectedWindow: TimeInterval = 10
    @State private var useManualTrim = false
    @State private var startOffset: TimeInterval = 0
    @State private var endOffset: TimeInterval = 0
    @State private var title: String = ""

    private let quickWindows: [TimeInterval] = [10, 15, 30]

    var body: some View {
        NavigationStack {
            ZStack {
                GoStatsTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        headerCard

                        if let recording {
                            windowSelector(recording: recording)
                            trimControls(recording: recording)

                            LiquidGlassContainer(cornerRadius: 22) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("TITLE")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(GoStatsTheme.primary)

                                    TextField("Clip title", text: $title)
                                        .textInputAutocapitalization(.words)
                                }
                            }

                            Button(action: createClip) {
                                Text("Save Clip")
                                    .font(.system(size: 15, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(GoStatsTheme.primary)
                                    )
                                    .foregroundStyle(.white)
                            }
                            .buttonStyle(.plain)
                        } else {
                            LiquidGlassContainer(cornerRadius: 22) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("No active recording")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(GoStatsTheme.text)
                                    Text("Start recording to tag clips for this event.")
                                        .font(.system(size: 12))
                                        .foregroundStyle(GoStatsTheme.text2)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Tag Clip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            title = defaultTitle()
            if let recording {
                configureOffsets(recording: recording)
            }
        }
    }

    private var headerCard: some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 6) {
                Text("EVENT")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.primary)

                Text(event.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.text)

                Text("\(periodLabel) • \(timeString(event.seconds))")
                    .font(.system(size: 12))
                    .foregroundStyle(GoStatsTheme.text2)
            }
        }
    }

    private func windowSelector(recording: VideoRecording) -> some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 12) {
                Text("WINDOW")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.primary)

                Toggle("Manual Trim", isOn: $useManualTrim)

                if !useManualTrim {
                    Picker("Recent window", selection: $selectedWindow) {
                        ForEach(quickWindows, id: \.self) { window in
                            Text("Last \(Int(window))s").tag(window)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedWindow) { _, _ in
                        configureOffsets(recording: recording)
                    }
                }
            }
        }
    }

    private func trimControls(recording: VideoRecording) -> some View {
        LiquidGlassContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 12) {
                Text("TRIM")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GoStatsTheme.primary)

                if useManualTrim {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Start: \(startOffset, specifier: "%.1f")s")
                            .font(.system(size: 12))
                            .foregroundStyle(GoStatsTheme.text2)
                        Slider(value: $startOffset, in: 0...maxDuration, step: 0.5)
                        Text("End: \(endOffset, specifier: "%.1f")s")
                            .font(.system(size: 12))
                            .foregroundStyle(GoStatsTheme.text2)
                        Slider(value: $endOffset, in: 0...maxDuration, step: 0.5)
                    }
                } else {
                    Text("\(startOffset, specifier: "%.1f")s → \(endOffset, specifier: "%.1f")s")
                        .font(.system(size: 12))
                        .foregroundStyle(GoStatsTheme.text2)
                }
            }
        }
        .onChange(of: useManualTrim) { _, newValue in
            if !newValue {
                configureOffsets(recording: recording)
            }
        }
    }

    private func createClip() {
        guard let recording else { return }
        let validStart = max(0, min(startOffset, maxDuration))
        let validEnd = max(validStart + 0.1, min(endOffset, maxDuration))
        let linkedPlayers = [event.primaryPlayerID, event.secondaryPlayerID].compactMap { $0 }

        let clip = Clip(
            gameID: gameID,
            recordingID: recording.id,
            startOffset: validStart,
            endOffset: validEnd,
            createdAt: Date(),
            title: title.isEmpty ? defaultTitle() : title,
            linkedEventIDs: [event.id],
            linkedPlayerIDs: linkedPlayers
        )

        var links: [ClipLink] = []
        if linkedPlayers.isEmpty {
            links.append(ClipLink(clipID: clip.id, eventID: event.id, playerID: nil))
        } else {
            for playerID in linkedPlayers {
                links.append(ClipLink(clipID: clip.id, eventID: event.id, playerID: playerID))
            }
        }

        clipStore.addClip(clip, links: links)
        dismiss()
    }

    private func configureOffsets(recording: VideoRecording) {
        let eventOffset = max(0, event.createdAt.timeIntervalSince(recording.startDate))
        let end = min(eventOffset, maxDuration)
        let start = max(0, end - selectedWindow)
        startOffset = start
        endOffset = max(end, start + 0.1)
    }

    private var recording: VideoRecording? {
        clipStore.recordingForEvent(event, gameID: gameID)
    }

    private var maxDuration: TimeInterval {
        guard let recording else { return 0 }
        if recording.isFinalized {
            return recording.duration
        }
        let elapsed = activeRecordingElapsed ?? recording.duration
        return max(recording.duration, elapsed)
    }

    private func defaultTitle() -> String {
        var pieces: [String] = [event.label]
        if let primaryName = playerName(for: event.primaryPlayerID) {
            pieces.append(primaryName)
        }
        pieces.append("\(periodLabel) \(timeString(event.seconds))")
        return pieces.joined(separator: " – ")
    }

    private func playerName(for id: UUID?) -> String? {
        guard let id else { return nil }
        return players.first(where: { $0.id == id })?.name
    }

    private func timeString(_ s: Int) -> String {
        let m = s / 60
        let sec = s % 60
        return String(format: "%02d:%02d", m, sec)
    }
}
