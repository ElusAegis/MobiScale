import Foundation
import DeviceCheck
import CryptoKit
import Security

// MARK: – Implementation
public actor SecureEnclaveService {

    // Hard-coded identifiers – customise once.
    private let bundleID = "com.yourcompany.moproapp"
    private let teamID   = "ABC123XYZ4"

    private var appID: String {
        return "\(teamID).\(bundleID)"
    }



    // ---------------------------------------------------------------------
    // 1. Generate (or reuse) an App Attest key and return its attestation
    // ---------------------------------------------------------------------
    public func generateAttestation(challenge: Data) async throws -> AttestationResult {

        guard DCAppAttestService.shared.isSupported else { throw SESError.unsupported }

        let keyID = try await getOrCreateKeyID()

        // Apple expects the SHA‑256 of the challenge as clientDataHash
        let clientHash = SHA256.hash(data: challenge)
        let attestation = try await DCAppAttestService.shared.attestKey(
            keyID,
            clientDataHash: Data(clientHash)
        )

        return AttestationResult(keyID: keyID,
                                 attestation: attestation,
                                 challenge: challenge)
    }

    // ---------------------------------------------------------------------
    // 2. Generate an assertion with the cached key
    // ---------------------------------------------------------------------
    public func generateAssertion(payload: Data) async throws -> AssertionResult {

        guard let keyID = UserDefaults.standard.string(forKey: "appAttestKeyID") else {
            throw SESError.noCachedKey
        }

        let clientHash = SHA256.hash(data: payload)
        let assertion = try await DCAppAttestService.shared.generateAssertion(
            keyID,
            clientDataHash: Data(clientHash)
        )

        return AssertionResult(
            appID: appID,
            keyID: keyID,
            assertion: assertion,
            payload: payload
        )
    }

    /// Returns a cached App Attest key ID, or generates & persists a new one.
    private func getOrCreateKeyID() async throws -> String {
        if let cached = UserDefaults.standard.string(forKey: "appAttestKeyID") {
            return cached
        }

        let newKeyID = try await DCAppAttestService.shared.generateKey()
        UserDefaults.standard.set(newKeyID, forKey: "appAttestKeyID")
        return newKeyID
    }
}
