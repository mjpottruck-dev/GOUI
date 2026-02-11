import Foundation
import MultipeerConnectivity
import UIKit

struct RosterSharePayload: Codable {
    var teamName: String
    var players: [RosterSharePlayer]

    struct RosterSharePlayer: Codable, Identifiable {
        var id: UUID
        var name: String
        var jerseyNumber: Int
        var position: Position
        var isStarter: Bool
        var isGoalie: Bool
    }

    init(team: Team) {
        teamName = team.name
        let starters = Set(team.startingOnFieldIDs)
        players = team.players.map {
            RosterSharePlayer(
                id: $0.id,
                name: $0.name,
                jerseyNumber: $0.number,
                position: $0.position,
                isStarter: starters.contains($0.id),
                isGoalie: $0.derivedIsGoalie
            )
        }
    }
}

final class RosterProximityShareService: NSObject, ObservableObject {
    @Published var status: String = "Bring another phone nearby to share."
    @Published var isConnected: Bool = false
    @Published var receivedPayload: RosterSharePayload? = nil

    private let serviceType = "goui-roster"
    private let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    private lazy var session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    private var outgoingPayload: RosterSharePayload?

    func startSharing(_ payload: RosterSharePayload) {
        outgoingPayload = payload
        receivedPayload = nil
        configureSession()
        startNearby()
    }

    func stop() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session.disconnect()
        advertiser = nil
        browser = nil
        isConnected = false
        status = "Sharing stopped."
    }

    private func configureSession() {
        session.delegate = self
    }

    private func startNearby() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()

        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)

        advertiser?.delegate = self
        browser?.delegate = self

        advertiser?.startAdvertisingPeer()
        browser?.startBrowsingForPeers()

        status = "Searching for nearby devices..."
    }

    private func sendPayloadIfPossible() {
        guard let outgoingPayload,
              !session.connectedPeers.isEmpty,
              let data = try? JSONEncoder().encode(outgoingPayload) else {
            return
        }

        do {
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            status = "Roster sent securely."
        } catch {
            status = "Send failed: \(error.localizedDescription)"
        }
    }
}

extension RosterProximityShareService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        Task { @MainActor in
            status = "Nearby sharing unavailable: \(error.localizedDescription)"
        }
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                                didReceiveInvitationFromPeer peerID: MCPeerID,
                                withContext context: Data?,
                                invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
}

extension RosterProximityShareService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        Task { @MainActor in
            status = "Peer discovery failed: \(error.localizedDescription)"
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
        Task { @MainActor in
            status = "Connecting to \(peerID.displayName)..."
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task { @MainActor in
            status = "Lost \(peerID.displayName). Keep devices close."
        }
    }
}

extension RosterProximityShareService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            isConnected = state == .connected
            switch state {
            case .connected:
                status = "Connected to \(peerID.displayName). Sending roster..."
                sendPayloadIfPossible()
            case .connecting:
                status = "Connecting to \(peerID.displayName)..."
            case .notConnected:
                status = "Not connected. Move phones closer and try again."
            @unknown default:
                status = "Unknown connection state."
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            do {
                receivedPayload = try JSONDecoder().decode(RosterSharePayload.self, from: data)
                status = "Received roster from \(peerID.displayName)."
            } catch {
                status = "Received invalid roster data."
            }
        }
    }

    func session(_ session: MCSession,
                             didReceive stream: InputStream,
                             withName streamName: String,
                             fromPeer peerID: MCPeerID) {}

    func session(_ session: MCSession,
                             didStartReceivingResourceWithName resourceName: String,
                             fromPeer peerID: MCPeerID,
                             with progress: Progress) {}

    func session(_ session: MCSession,
                             didFinishReceivingResourceWithName resourceName: String,
                             fromPeer peerID: MCPeerID,
                             at localURL: URL?,
                             withError error: Error?) {}
}
