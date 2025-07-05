// Services/RandomnessService.swift
import Foundation
import CryptoKit

public protocol RandomnessProvider {
    func fetchChallenge() async throws -> RandomnessChallenge
}

/// Concrete impl for LoE-drand beacon.
public actor DrandRandomnessService: RandomnessProvider {

    public init(session: URLSession = .shared) { self.session = session }
    private let session: URLSession

    public func fetchChallenge() async throws -> RandomnessChallenge {
        struct DrandJSON: Decodable { let round: UInt64; let randomness: String }

        let url = URL(string: "https://api.drand.sh/public/latest")!
        let (data, _) = try await session.data(from: url)
        let dto = try JSONDecoder().decode(DrandJSON.self, from: data)

        guard let fullEntropy = Data(hexString: dto.randomness) else {
            throw RandomnessError.decode("hex decode failed")
        }

        let bytes = Data(SHA256.hash(data: fullEntropy).prefix(32))
        return RandomnessChallenge(
            bytes: bytes,
            meta: .init(source: "drand (LoE)",
                        round: dto.round,
                        fetchedAt: Date()))
    }
}
