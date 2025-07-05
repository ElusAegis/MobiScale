import Foundation

// MARK: – Data models
public struct AttestationResult: Sendable {
    public let keyID: String
    public let attestation: Data
    public let challenge: Data       // 32-byte random
}

// ---------------------------------------------------------------------
// Fallback: Generate a dummy assertion result for testing or error scenarios
// ---------------------------------------------------------------------
public func generateDummyAssertion(payload: Data) -> AssertionResult {
    let dummyKeyID = "dummy-key-id"
    let dummyAppID = "TEAM.some.app"
    let dummyAssertion = Data("dummy-assertion".utf8)

    return AssertionResult(
        appID: dummyAppID,
        keyID: dummyKeyID,
        assertion: dummyAssertion,
        payload: payload
    )
}

public struct AssertionResult: Sendable {
    public let appID: String
    public let keyID: String
    public let assertion: Data
    public let payload: Data         // arbitrary caller-supplied bytes
}


// ---------------------------------------------------------------------
// Fallback: Generate a dummy attestation result for testing or error scenarios
// ---------------------------------------------------------------------
public func generateDummyAttestation(challenge: Data) -> AttestationResult {
    let dummyKeyID = "dummy-key-id"
    let dummyAttestation = Data("dummy-attestation".utf8)

    return AttestationResult(
        keyID: dummyKeyID,
        attestation: dummyAttestation,
        challenge: challenge
    )
}

// MARK: – Error domain
public enum SESError: Error {
    case unsupported
    case keychainFailure(OSStatus)
    case noCachedKey
}
