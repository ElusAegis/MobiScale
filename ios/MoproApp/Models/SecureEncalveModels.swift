import Foundation

// MARK: – Data models
public struct AttestationResult: Sendable {
    public let keyID: String
    public let attestation: Data
    public let challenge: Data       // 32-byte random
}

public struct AssertionResult: Sendable {
    public let appID: String
    public let keyID: String
    public let assertion: Data
    public let payload: Data         // arbitrary caller-supplied bytes
}

// MARK: – Error domain
public enum SESError: Error {
    case unsupported
    case keychainFailure(OSStatus)
    case noCachedKey
}
