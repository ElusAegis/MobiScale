import Foundation

public struct RandomnessMeta: Sendable, Codable {
    public let source: String        // "drand (LoE)"
    public let round: UInt64         // 0 when N/A
    public let fetchedAt: Date
}

/// 32-byte challenge + provenance.
public struct RandomnessChallenge: Sendable {
    public let bytes: Data           // exactly 32 bytes
    public let meta: RandomnessMeta

    /// Convenience hex for logs / CLI flags.
    public var hex: String { bytes.hexString }
}

// MARK: - Randomness domain‑specific errors
public enum RandomnessError: Error {
    case decode(String)          // Failed to decode or parse remote entropy
}
