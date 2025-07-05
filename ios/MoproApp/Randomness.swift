//
//  Utils.swift
//  app-attester
//
//  Created by Artem Grigor on 05/07/2025.
//

import Foundation

//
//  Utils.swift
//  app-attester
//
//  Created by Artem Grigor on 05/07/2025.
//  Re‑factored on 05/07/2025 to expose a reusable randomness helper.
//

import Foundation
import CryptoKit

// MARK: - Public types

/// Metadata + verifiable challenge derived from an external randomness beacon.
public struct RandomnessInfo: Sendable {
    public let source: String        // e.g. "drand (LoE)"
    public let round: UInt64         // drand round; `0` for sources without rounds
    public let fetchedAt: Date       // when we retrieved it
    public let rawRandomness: Data   // full entropy (≥ 64 bytes for LoE)

    /// First 32 bytes of SHA‑256(rawRandomness).
    public var challenge: Data { Data(SHA256.hash(data: rawRandomness)) }
    public var challenge32: Data { Data(challenge.prefix(32)) }

    /// Hex‑encoded for easy logging / persistence.
    public var challengeHex: String { challenge.hexString }
    public var challenge32Hex: String { challenge32.hexString }
}

/// Errors thrown by the randomness helper.
public enum RandomnessError: Error {
    case network(String)
    case decode(String)
    case unsupported(String)
}

// MARK: - API surface

public struct RandomnessProvider {

    /// Fetches verifiable randomness from League‑of‑Entropy’s drand beacon
    /// and returns a 32‑byte challenge plus metadata.
    ///
    /// Re‑fetch later with:
    /// ```
    /// https://api.drand.sh/public/<round>
    /// ```
    /// Verify BLS signature with drand public key set if you need full auditability.
    ///
    /// - Throws: `RandomnessError`
    public static func fetchLoEChallenge() async throws -> RandomnessInfo {
        struct DrandJSON: Decodable {
            let round: UInt64
            let randomness: String   // 64‑byte hex string (512 bits)
        }

        guard let url = URL(string: "https://api.drand.sh/public/latest") else {
            throw RandomnessError.unsupported("Invalid drand endpoint")
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        let decoded: DrandJSON
        do {
            decoded = try JSONDecoder().decode(DrandJSON.self, from: data)
        } catch {
            throw RandomnessError.decode("drand JSON: \(error)")
        }

        guard let raw = Data(hexString: decoded.randomness) else {
            throw RandomnessError.decode("Hex decoding failed")
        }

        return RandomnessInfo(
            source: "drand (LoE)",
            round: decoded.round,
            fetchedAt: Date(),
            rawRandomness: raw
        )
    }
}

// MARK: - Helpers

private extension Data {
    /// Convert hex string → Data. Returns `nil` on malformed input.
    init?(hexString: String) {
        let length = hexString.count
        guard length.isMultiple(of: 2) else { return nil }

        var data = Data(capacity: length / 2)
        var index = hexString.startIndex
        for _ in 0..<(length / 2) {
            let next = hexString.index(index, offsetBy: 2)
            guard let byte = UInt8(hexString[index..<next], radix: 16) else { return nil }
            data.append(byte)
            index = next
        }
        self = data
    }

    /// Hex‑encode data (lower‑case, no prefix).
    var hexString: String { map { String(format: "%02x", $0) }.joined() }
}
