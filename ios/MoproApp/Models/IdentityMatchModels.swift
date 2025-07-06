import Foundation

/// Face embedding data for a detected face
public struct FaceMetadata: Codable, Sendable {
    public let embedding: [Float]
    public let photoHash: Data
    public let timestamp: Date
    
    public init(embedding: [Float], photoHash: Data) {
        self.embedding = embedding
        self.photoHash = photoHash
        self.timestamp = Date()
    }
}

/// Output produced after the ML model compares the passport photo and selfie.
/// This struct is JSON-encodable and can be safely sent to the existing proof pipeline.
public struct IdentityMatchOutput: Codable, Sendable {
    public let passportPhotoHash: Data   // SHA-256 of the selected passport image
    public let selfiePhotoHash:   Data   // SHA-256 of the selfie / screenshot
    public let modelId:           String // e.g. "passport-selfie-v0.1"
    public let score:             Float    // ML score ‑ same person cofidence
}
