// ─────────────────────────────────────────────────────────────────────
// RosterSharingService.swift
// GOUI
//
// MultipeerConnectivity-based roster sharing between nearby devices.
//
// ⚠️  REQUIRED Info.plist entries (add manually in Xcode):
//
//   Key: NSLocalNetworkUsageDescription
//   Value: "GoalStats uses your local network to share rosters with nearby devices."
//
//   Key: NSBonjourServices
//   Value: (Array)
//     - "_gostats-roster._tcp"
//     - "_gostats-roster._udp"
// ─────────────────────────────────────────────────────────────────────

import Foundation
import MultipeerConnectivity
import UIKit
import Combine

// MARK: - Shareable Payload

struct SharedRoster: Codable {
    let teamName: String
    let players: [SharedPlayer]

    struct SharedPlayer: Codable {
        let name: String
        let number: Int
        let position: String
    }

    init(team: Team) {
        teamName = team.name
        players = team.players.map {
            SharedPlayer(name: $0.name, number: $0.number, position: $0.position.rawValue)
        }
    }
}

// MARK: - State

enum SharingState: Equatable {
    case idle
    case searching
    case peerFound(String)
    case sending
    case sent
    case failed(String)
    case cancelled
    case receivingInvite(String)
    case connecting          // receiver accepted invite, waiting for data
    case received

    static func == (lhs: SharingState, rhs: SharingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.searching, .searching),
             (.sending, .sending),
             (.sent, .sent),
             (.cancelled, .cancelled),
             (.connecting, .connecting),
             (.received, .received):
            return true
        case let (.peerFound(a), .peerFound(b)):
            return a == b
        case let (.failed(a), .failed(b)):
            return a == b
        case let (.receivingInvite(a), .receivingInvite(b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - Service

final class RosterSharingService: NSObject, ObservableObject {

    // ── Sender state ──
    @Published var state: SharingState = .idle

    // ── Receiver state ──
    @Published var showingIncomingInvite = false
    @Published var incomingPeerName: String = ""
    @Published var receivedRoster: SharedRoster?

    // ── Internals ──
    private static let serviceType = "gostats-roster"
    private static let ackData = Data("ACK".utf8)
    private let myPeerID: MCPeerID
    private var session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    private var outgoingData: Data?
    private var timeoutTask: DispatchWorkItem?
    private var pendingInvitationHandler: ((Bool, MCSession?) -> Void)?
    private var hasReceivedRoster = false
    private var shareID: String?            // unique ID per share attempt (sender)
    private var incomingShareID: String?     // ID of the share we're being invited to (receiver)
    private var dismissedShareIDs = Set<String>()  // share IDs already accepted/declined

    // MARK: - Init / Cleanup

    override init() {
        let displayName = UIDevice.current.name
        myPeerID = MCPeerID(displayName: displayName)
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        super.init()
        session.delegate = self
    }

    deinit {
        stopAll()
    }

    // MARK: - Sender API

    /// Start browsing for nearby receivers. When one accepts, send the roster.
    func startSharing(team: Team) {
        stopAll()
        hasReceivedRoster = false
        shareID = UUID().uuidString

        let payload = SharedRoster(team: team)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(payload) else {
            setState(.failed("Could not encode roster"))
            startListening()
            return
        }
        outgoingData = data

        // Fresh session
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self

        // Browse to find receivers (who are advertising)
        // Sender does NOT advertise — only browses
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: Self.serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()

        setState(.searching)

        // 30-second timeout
        let timeout = DispatchWorkItem { [weak self] in
            guard let self, self.state == .searching else { return }
            self.setState(.failed("No devices found"))
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                guard let self else { return }
                self.stopAll()
                self.startListening()
                self.setState(.idle)
            }
        }
        timeoutTask = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0, execute: timeout)
    }

    func cancelSharing() {
        timeoutTask?.cancel()
        timeoutTask = nil
        stopAll()
        startListening()
        setState(.cancelled)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.setState(.idle)
        }
    }

    // MARK: - Receiver API (passive)

    /// Start passive advertising so nearby senders can discover us automatically.
    /// Receiver does NOT browse — only advertises to be discoverable.
    func startListening() {
        guard advertiser == nil else { return }

        hasReceivedRoster = false
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self

        // Advertise so senders' browsers can find us
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: Self.serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
    }

    /// Stop passive listening. Call in onDisappear.
    func stopListening() {
        // Only stop if we're not actively sharing as sender
        guard outgoingData == nil else { return }
        stopAll()
    }

    /// Accept incoming roster invitation.
    func acceptInvitation() {
        print("[RosterShare] acceptInvitation() called")
        print("[RosterShare]   pendingInvitationHandler is \(pendingInvitationHandler == nil ? "nil ⚠️" : "set ✅")")
        print("[RosterShare]   session peer count: \(session.connectedPeers.count)")
        if let id = incomingShareID { dismissedShareIDs.insert(id) }
        pendingInvitationHandler?(true, session)
        pendingInvitationHandler = nil
        showingIncomingInvite = false
        // Pause advertising while the transfer completes
        advertiser?.stopAdvertisingPeer()
        state = .connecting
        print("[RosterShare]   state set to .connecting, waiting for data to arrive...")
    }

    /// Send ACK to sender confirming the roster was saved. Call from HomeView after team creation.
    func sendAck() {
        guard !session.connectedPeers.isEmpty else {
            print("[RosterShare] sendAck() — no connected peers, cannot send ACK")
            return
        }
        do {
            try session.send(Self.ackData, toPeers: session.connectedPeers, with: .reliable)
            print("[RosterShare] ✅ ACK sent to sender after team was saved")
        } catch {
            print("[RosterShare] ⚠️ ACK send failed: \(error.localizedDescription)")
        }
    }

    /// Decline incoming roster invitation.
    func declineInvitation() {
        print("[RosterShare] declineInvitation() called")
        if let id = incomingShareID { dismissedShareIDs.insert(id) }
        pendingInvitationHandler?(false, nil)
        pendingInvitationHandler = nil
        showingIncomingInvite = false
        incomingPeerName = ""
        incomingShareID = nil
        state = .idle
        // Advertiser keeps running — can still receive from other senders
    }

    // MARK: - Private Helpers

    private func setState(_ newState: SharingState) {
        Task { @MainActor in
            self.state = newState
        }
    }

    private func stopAdvertisingAndBrowsing() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
    }

    private func stopAll() {
        timeoutTask?.cancel()
        timeoutTask = nil
        stopAdvertisingAndBrowsing()
        session.disconnect()
        advertiser = nil
        browser = nil
        outgoingData = nil
        pendingInvitationHandler = nil
    }

    private func sendDataToPeers() {
        guard let data = outgoingData, !session.connectedPeers.isEmpty else {
            print("[RosterShare] sendDataToPeers() — no data or no peers")
            return
        }
        setState(.sending)
        do {
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            timeoutTask?.cancel()
            print("[RosterShare] Data sent to \(session.connectedPeers.count) peer(s), waiting for ACK...")
            // Wait for ACK from receiver before showing .sent
            let ackTimeout = DispatchWorkItem { [weak self] in
                guard let self else { return }
                print("[RosterShare] ACK timeout (10s) — showing sent anyway")
                self.showSentAndCleanup()
            }
            timeoutTask = ackTimeout
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0, execute: ackTimeout)
        } catch {
            print("[RosterShare] Send FAILED: \(error.localizedDescription)")
            setState(.failed("Send failed: \(error.localizedDescription)"))
            stopAll()
            startListening()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.setState(.idle)
            }
        }
    }

    private func showSentAndCleanup() {
        setState(.sent)
        stopAdvertisingAndBrowsing()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self else { return }
            self.stopAll()
            self.startListening()
            self.setState(.idle)
        }
    }
}

// MARK: - MCSessionDelegate

extension RosterSharingService: MCSessionDelegate {

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange newState: MCSessionState) {
        Task { @MainActor in
            print("[RosterShare] Session state changed: \(newState.rawValue) for peer: \(peerID.displayName)")
            print("[RosterShare]   outgoingData is \(self.outgoingData == nil ? "nil (receiver)" : "set (sender)")")
            switch newState {
            case .connected:
                print("[RosterShare]   CONNECTED to \(peerID.displayName)")
                // If we have outgoing data, we're the sender — send it now
                if self.outgoingData != nil {
                    self.setState(.peerFound(peerID.displayName))
                    // Brief delay so the user sees "Found [name]"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                        self?.sendDataToPeers()
                    }
                } else {
                    print("[RosterShare]   We're the receiver — waiting for data...")
                }
            case .notConnected:
                print("[RosterShare]   NOT CONNECTED (disconnected) from \(peerID.displayName), current state: \(self.state)")
                // Peer disconnected — fail if we were mid-send or waiting for data
                if case .sending = self.state {
                    self.setState(.failed("Peer disconnected"))
                    self.stopAll()
                    self.startListening()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                        self?.setState(.idle)
                    }
                } else if case .connecting = self.state {
                    self.setState(.failed("Connection lost before roster arrived"))
                    self.stopAll()
                    self.startListening()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                        self?.setState(.idle)
                    }
                }
            case .connecting:
                print("[RosterShare]   CONNECTING to \(peerID.displayName)...")
                break
            @unknown default:
                break
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            print("[RosterShare] didReceive data (\(data.count) bytes) from \(peerID.displayName)")

            // ── ACK from receiver → we're the sender ──
            if data == Self.ackData {
                print("[RosterShare] ✅ Received ACK — receiver confirmed roster saved!")
                self.timeoutTask?.cancel()
                self.timeoutTask = nil
                self.showSentAndCleanup()
                return
            }

            // ── Roster data → we're the receiver ──
            print("[RosterShare] Treating as roster data. hasReceivedRoster=\(self.hasReceivedRoster)")
            guard !self.hasReceivedRoster else {
                print("[RosterShare] ⚠️ Already received a roster this session — ignoring")
                return
            }
            do {
                let roster = try JSONDecoder().decode(SharedRoster.self, from: data)
                print("[RosterShare] ✅ Decoded roster: team=\(roster.teamName), \(roster.players.count) players")
                self.hasReceivedRoster = true
                if let id = self.incomingShareID { self.dismissedShareIDs.insert(id) }
                self.receivedRoster = roster
                print("[RosterShare] receivedRoster set, now setting state to .received")
                self.state = .received
                print("[RosterShare] state = .received ✅ (ACK will be sent by HomeView after team is created)")

                // After 2s delay, reset and resume passive advertising
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    guard let self else { return }
                    print("[RosterShare] Post-receive cleanup: disconnecting session, restarting advertising")
                    self.session.disconnect()
                    self.hasReceivedRoster = false
                    self.incomingShareID = nil
                    // Fresh session for future connections
                    self.session = MCSession(peer: self.myPeerID, securityIdentity: nil, encryptionPreference: .required)
                    self.session.delegate = self
                    // Restart passive advertising
                    self.advertiser?.startAdvertisingPeer()
                    self.setState(.idle)
                }
            } catch {
                print("[RosterShare] ❌ DECODE FAILED: \(error)")
                print("[RosterShare]   Raw data (first 200 chars): \(String(data: data.prefix(200), encoding: .utf8) ?? "not UTF-8")")
            }
        }
    }

    // Unused required delegate methods
    func session(_ session: MCSession, didReceive stream: InputStream, withName: String, fromPeer: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName: String, fromPeer: MCPeerID, with: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName: String, fromPeer: MCPeerID, at: URL?, withError: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension RosterSharingService: MCNearbyServiceAdvertiserDelegate {

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        setState(.failed("Nearby sharing unavailable. Check that Wi-Fi and Bluetooth are enabled."))
        stopAll()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.setState(.idle)
        }
    }

    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        Task { @MainActor in
            let incomingID = context.flatMap { String(data: $0, encoding: .utf8) }
            print("[RosterShare] Received invitation from \(peerID.displayName), shareID=\(incomingID ?? "none")")

            if self.outgoingData != nil {
                print("[RosterShare]   We're the sender — auto-accepting")
                invitationHandler(true, self.session)
            } else if self.hasReceivedRoster {
                print("[RosterShare]   Already received — rejecting")
                invitationHandler(false, nil)
            } else if let id = incomingID, self.dismissedShareIDs.contains(id) {
                print("[RosterShare]   Share ID already dismissed — rejecting")
                invitationHandler(false, nil)
            } else if case .receivingInvite = self.state {
                print("[RosterShare]   Already showing invite — rejecting duplicate")
                invitationHandler(false, nil)
            } else {
                print("[RosterShare]   Showing invite popup to user ✅")
                self.incomingPeerName = peerID.displayName
                self.incomingShareID = incomingID
                self.pendingInvitationHandler = invitationHandler
                self.state = .receivingInvite(peerID.displayName)
                self.showingIncomingInvite = true
            }
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension RosterSharingService: MCNearbyServiceBrowserDelegate {

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        setState(.failed("Could not search for nearby devices. Check that Wi-Fi and Bluetooth are enabled."))
        stopAll()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.setState(.idle)
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        // Don't connect to ourselves
        guard peerID != myPeerID else { return }
        // Don't re-invite if we already sent successfully
        guard !hasReceivedRoster else { return }
        // Send invitation with our shareID so the receiver can deduplicate
        let context = shareID?.data(using: .utf8)
        print("[RosterShare] Browser found peer: \(peerID.displayName) — sending invitation with shareID=\(shareID ?? "nil")")
        browser.invitePeer(peerID, to: session, withContext: context, timeout: 15)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        // No action needed
    }
}
