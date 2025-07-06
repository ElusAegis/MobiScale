import Foundation
import PhotosUI
import CryptoKit
import UIKit

@MainActor
final class IdentityMatchViewModel: ObservableObject {
    enum Step { case selectPassport, captureSelfie, comparing, success, done }

    
    @Published var step: Step = .selectPassport
    @Published var resultData: Data?
    @Published var error: String?
    @Published var isProcessing = false
    @Published var passportValidated = false
    @Published var selfieValidated = false
    @Published var output: IdentityMatchOutput?
    private var svc = FaceEmbeddingService()


    private let modelId = "passport-selfie-v0.1"
    private var passportMetadata: FaceMetadata?
    private var selfieMetadata: FaceMetadata?

    func processImage(_ imageData: Data, for type: ImageType) {
        isProcessing = true
        error = nil
        
        Task {
            let photoHash = Data(SHA256.hash(data: imageData))
            
            do {
                // Add timeout protection
                let faceEmbedding = try await withTimeout(seconds: 30) {
                    try self.svc.embedding(from: imageData)
                }
                
                await MainActor.run {
                    switch type {
                    case .passport:
                        self.passportMetadata = FaceMetadata.init(embedding: faceEmbedding, photoHash: photoHash)
                        self.passportValidated = true
                        // Don't auto-advance, let user choose when to proceed
                    case .selfie:
                        self.selfieMetadata = FaceMetadata.init(embedding: faceEmbedding, photoHash: photoHash)
                        self.selfieValidated = true
                        // Don't auto-advance, let user choose when to proceed
                    }
                    self.isProcessing = false
                }
            } catch {
                await MainActor.run {
                    switch type {
                    case .passport:
                        if error.localizedDescription.contains("No face found") {
                            self.error = "No face detected in passport photo. Please try again with a clearer photo."
                        } else if error.localizedDescription.contains("timeout") {
                            self.error = "Processing timed out. Please try again."
                        } else {
                            self.error = "Failed to process passport photo: \(error.localizedDescription)"
                        }
                        self.passportValidated = false
                        // Reset passport photo when it fails
                        self.passportMetadata = nil
                    case .selfie:
                        if error.localizedDescription.contains("No face found") {
                            self.error = "No face detected in selfie. Please try again with a clearer photo."
                        } else if error.localizedDescription.contains("timeout") {
                            self.error = "Processing timed out. Please try again."
                        } else {
                            self.error = "Failed to process selfie: \(error.localizedDescription)"
                        }
                        self.selfieValidated = false
                        // Reset selfie photo when it fails
                        self.selfieMetadata = nil
                    }
                    self.isProcessing = false
                }
            }
        }
    }
    
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw NSError(domain: "Timeout", code: -1, userInfo: [NSLocalizedDescriptionKey: "Operation timed out after \(seconds) seconds"])
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    func compareFaces(onComplete: @escaping ((IdentityMatchOutput) -> Void)) {
        guard let passportMetadata = passportMetadata,
              let selfieMetadata = selfieMetadata else {
            error = "Missing face embeddings"
            return
        }
        
        step = .comparing
        
        Task {
            // Placeholder face comparison - compute cosine similarity
            let score = svc.cosine(passportMetadata.embedding, selfieMetadata.embedding)
            let threshold: Float = 0.6
            let match = score >= threshold
            
            let output = IdentityMatchOutput(
                passportPhotoHash: passportMetadata.photoHash,
                selfiePhotoHash: selfieMetadata.photoHash,
                modelId: modelId,
                score: score,
            )
            
            await MainActor.run {
                if match {
                    self.output = output
                    print("✅ Verification successful! Score: \(score)")
                    onComplete(output)
                } else {
                    self.error = "Sorry, we could not quite match the photo to yourself. Confidence: \(score) > threshold: \(threshold). Please try again."
                    print("🧠 No match found. Cosine similarity: \(score)")
                    // Reset both photos when verification fails
                    self.resetForRetry()
                }
            }
        }
    }
    
    func getOutput() -> IdentityMatchOutput? {
        return output
    }
    
    func resetForRetry() {
        step = .selectPassport
        resultData = nil
        output = nil
        isProcessing = false
        passportValidated = false
        selfieValidated = false
        passportMetadata = nil
        selfieMetadata = nil
        print("🔄 Reset for retry - all state cleared")
    }
    
    func resetPassportOnly() {
        passportValidated = false
        passportMetadata = nil
        error = nil
        print("🔄 Reset passport only")
    }
    
    func resetSelfieOnly() {
        selfieValidated = false
        selfieMetadata = nil
        error = nil
        print("🔄 Reset selfie only")
    }
    
    func retryCurrentStep() {
        error = nil
        isProcessing = false
        print("🔄 Retrying current step")
    }
}

enum ImageType {
    case passport
    case selfie
}

enum FaceDetectionError: Error {
    case invalidImage
    case noFaceDetected
}
