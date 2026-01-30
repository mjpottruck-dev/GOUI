import Foundation

@MainActor
final class ChatStore: ObservableObject {
    @Published private(set) var messages: [ChatMessage] = [] {
        didSet { save() }
    }

    private let fileURL: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = docs.appendingPathComponent("team_chat.json")
        load()
    }

    func messages(for teamID: UUID) -> [ChatMessage] {
        messages.filter { $0.threadID == teamID }.sorted { $0.createdAt < $1.createdAt }
    }

    func sendMessage(teamID: UUID, senderID: String, senderName: String, text: String) {
        let message = ChatMessage(
            threadID: teamID,
            senderUserID: senderID,
            senderName: senderName,
            createdAt: Date(),
            text: text
        )
        messages.append(message)
    }

    func deleteMessage(_ message: ChatMessage) {
        guard let idx = messages.firstIndex(where: { $0.id == message.id }) else { return }
        messages[idx].isDeleted = true
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([ChatMessage].self, from: data) else {
            messages = []
            return
        }
        messages = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(messages) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
}
