import SwiftUI

struct TeamChatView: View {
    @Bindable var teamStore: TeamStore
    let teamID: UUID

    @EnvironmentObject var chatStore: ChatStore
    @EnvironmentObject var roleManager: RoleManager
    @EnvironmentObject var permissionService: PermissionService
    @EnvironmentObject var appState: AppState

    @State private var messageText: String = ""
    @State private var showSwitcher = false

    private var teamName: String {
        teamStore.teams.first(where: { $0.id == teamID })?.name ?? "Team Chat"
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(chatStore.messages(for: teamID)) { message in
                            chatBubble(message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                .onChange(of: chatStore.messages(for: teamID).count) { _, _ in
                    if let last = chatStore.messages(for: teamID).last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }

            Divider()

            HStack(spacing: 12) {
                TextField("Message", text: $messageText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)

                Button("Send") {
                    sendMessage()
                }
                .buttonStyle(.borderedProminent)
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(12)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
        }
        .navigationTitle(teamName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSwitcher = true
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
            }
        }
        .background(GoStatsTheme.bg)
        .sheet(isPresented: $showSwitcher) {
            TeamSwitcherSheet(teamStore: teamStore) { picked in
                appState.currentTeamID = picked
            }
        }
    }

    private func chatBubble(_ message: ChatMessage) -> some View {
        let isMe = message.senderUserID == roleManager.userID
        return HStack {
            if isMe { Spacer() }
            VStack(alignment: .leading, spacing: 4) {
                Text(message.senderName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(GoStatsTheme.text2)
                Text(message.isDeleted ? "Message removed" : message.text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(GoStatsTheme.text)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isMe ? GoStatsTheme.primary.opacity(0.2) : Color(uiColor: .secondarySystemGroupedBackground))
            )
            if !isMe { Spacer() }
        }
    }

    private func sendMessage() {
        guard permissionService.canChat(teamID: teamID) else { return }
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        chatStore.sendMessage(teamID: teamID, senderID: roleManager.userID, senderName: roleManager.displayName, text: trimmed)
        messageText = ""
    }
}
