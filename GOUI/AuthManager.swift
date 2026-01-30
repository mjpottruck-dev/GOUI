import AuthenticationServices
import CloudKit
import Foundation
import UIKit

@MainActor
final class AuthManager: NSObject, ObservableObject {
    @Published private(set) var currentUser: AuthUser?
    @Published private(set) var isSigningIn: Bool = false
    @Published private(set) var lastErrorMessage: String?

    private let userIDKey = "gostats.auth.userID"
    private let container: CKContainer?
    private let database: CKDatabase?

    override init() {
        container = CloudKitAvailability.defaultContainer()
        database = container?.privateCloudDatabase
        super.init()
        Task {
            await restoreSession()
        }
    }

    var isSignedIn: Bool {
        currentUser != nil
    }

    func signIn() async {
        guard cloudKitAvailable else {
            lastErrorMessage = CloudKitUnavailableError().localizedDescription
            return
        }
        guard !isSigningIn else { return }
        isSigningIn = true
        lastErrorMessage = nil
        defer { isSigningIn = false }
        do {
            let credential = try await performSignIn()
            let displayName = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            let userID = credential.user
            KeychainHelper.save(userID, for: userIDKey)
            let userRecordID = try await fetchUserRecordID()
            let resolvedDisplayName = displayName.isEmpty ? "GoStats User" : displayName
            let authUser = try await upsertUser(
                userID: userID,
                displayName: resolvedDisplayName,
                userRecordName: userRecordID?.recordName
            )
            currentUser = authUser
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func signOut() {
        KeychainHelper.delete(userIDKey)
        currentUser = nil
    }

    func restoreSession() async {
        guard cloudKitAvailable else { return }
        guard let storedUserID = KeychainHelper.read(userIDKey) else { return }
        do {
            let userRecordID = try await fetchUserRecordID()
            let user = try await fetchUser(userID: storedUserID)
            if var user {
                if user.userRecordName == nil, let recordName = userRecordID?.recordName {
                    user.userRecordName = recordName
                    user = try await saveUser(user)
                }
                currentUser = user
            } else {
                let created = try await upsertUser(
                    userID: storedUserID,
                    displayName: "GoStats User",
                    userRecordName: userRecordID?.recordName
                )
                currentUser = created
            }
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    private func performSignIn() async throws -> ASAuthorizationAppleIDCredential {
        try await withCheckedThrowingContinuation { continuation in
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            signInContinuation = continuation
            controller.performRequests()
        }
    }

    private var signInContinuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?

    private var cloudKitAvailable: Bool {
        container != nil && database != nil
    }

    private func fetchUserRecordID() async throws -> CKRecord.ID? {
        guard let container else { throw CloudKitUnavailableError() }
        try await withCheckedThrowingContinuation { continuation in
            container.fetchUserRecordID { recordID, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: recordID)
                }
            }
        }
    }

    private func fetchUser(userID: String) async throws -> AuthUser? {
        guard let database else { throw CloudKitUnavailableError() }
        let recordID = CKRecord.ID(recordName: userID)
        return try await withCheckedThrowingContinuation { continuation in
            database.fetch(withRecordID: recordID) { record, error in
                if let ckError = error as? CKError, ckError.code == .unknownItem {
                    continuation.resume(returning: nil)
                    return
                }
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let record else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: AuthManager.decodeUser(from: record))
            }
        }
    }

    private func upsertUser(userID: String, displayName: String, userRecordName: String?) async throws -> AuthUser {
        let now = Date()
        if var existing = try await fetchUser(userID: userID) {
            existing.displayName = displayName
            existing.userRecordName = userRecordName
            existing.updatedAt = now
            return try await saveUser(existing)
        }
        let newUser = AuthUser(
            userID: userID,
            displayName: displayName,
            role: .athlete,
            userRecordName: userRecordName,
            createdAt: now,
            updatedAt: now
        )
        return try await saveUser(newUser)
    }

    private func saveUser(_ user: AuthUser) async throws -> AuthUser {
        guard let database else { throw CloudKitUnavailableError() }
        let recordID = CKRecord.ID(recordName: user.userID)
        let record = CKRecord(recordType: CloudRecordType.user, recordID: recordID)
        record["displayName"] = user.displayName as CKRecordValue
        record["role"] = user.role.rawValue as CKRecordValue
        record["userRecordName"] = (user.userRecordName ?? "") as CKRecordValue
        record["createdAt"] = user.createdAt as CKRecordValue
        record["updatedAt"] = user.updatedAt as CKRecordValue

        return try await withCheckedThrowingContinuation { continuation in
            database.save(record) { saved, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let saved {
                    continuation.resume(returning: AuthManager.decodeUser(from: saved) ?? user)
                } else {
                    continuation.resume(returning: user)
                }
            }
        }
    }

    nonisolated private static func decodeUser(from record: CKRecord) -> AuthUser? {
        guard let displayName = record["displayName"] as? String,
              let roleRaw = record["role"] as? String,
              let role = UserRole.fromStoredValue(roleRaw),
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date
        else { return nil }
        let userRecordName = record["userRecordName"] as? String
        return AuthUser(
            userID: record.recordID.recordName,
            displayName: displayName,
            role: role,
            userRecordName: userRecordName?.isEmpty == true ? nil : userRecordName,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension AuthManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            signInContinuation?.resume(throwing: NSError(domain: "Auth", code: -1))
            signInContinuation = nil
            return
        }
        signInContinuation?.resume(returning: credential)
        signInContinuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        signInContinuation?.resume(throwing: error)
        signInContinuation = nil
    }
}

extension AuthManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}
