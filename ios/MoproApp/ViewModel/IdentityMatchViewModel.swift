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
    private var onComplete: ((Data) -> Void)?

    func processImage(_ imageData: Data, for type: ImageType) {
        isProcessing = true
        error = nil
        
        Task {
            let photoHash = Data(SHA256.hash(data: imageData))
            
            do {
                let faceEmbedding = try svc.embedding(from: imageData)
                
                await MainActor.run {
                    switch type {
                    case .passport:
                        self.passportMetadata = FaceMetadata.init(embedding: faceEmbedding, photoHash: photoHash)
                        self.passportValidated = true
                        self.step = .captureSelfie
                    case .selfie:
                        self.selfieMetadata = FaceMetadata.init(embedding: faceEmbedding, photoHash: photoHash)
                        self.selfieValidated = true
                        self.compareFaces()
                    }
                    self.isProcessing = false
                }
            } catch {
                await MainActor.run {
                    switch type {
                    case .passport:
                        self.error = "No face detected in passport photo. Please try again."
                        self.passportValidated = false
                    case .selfie:
                        self.error = "No face detected in selfie. Please try again."
                        self.selfieValidated = false
                    }
                    self.isProcessing = false
                }
            }
        }
    }

    private func compareFaces() {
        guard let passportMetadata = passportMetadata,
              let selfieMetadata = selfieMetadata,
              let onComplete = onComplete else {
            error = "Missing face embeddings"
            return
        }
        
        step = .comparing
        
        Task {
            // Placeholder face comparison - compute cosine similarity
            let score = svc.cosine(passportMetadata.embedding, selfieMetadata.embedding)
            let threshold: Float = 0.7
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
                    if let json = try? JSONEncoder().encode(output) {
                        self.resultData = json
                        self.step = .success
                    } else {
                        self.error = "Failed to encode result"
                        self.step = .selectPassport
                    }
                } else {
                    self.error = "Sorry, we could not quite match the photo to yourself. Please try again."
                    print("")
                    self.step = .selectPassport
                }
            }
        }
    }

    func setCompletionHandler(_ completion: @escaping (Data) -> Void) {
        self.onComplete = completion
    }
    
    func proceedToAttestation() {
        guard let onComplete = onComplete,
              let resultData = resultData else { return }
        step = .done
        onComplete(resultData)
    }

    func resetForRetry() {
        step = .selectPassport
        error = nil
        resultData = nil
        output = nil
        isProcessing = false
        passportValidated = false
        selfieValidated = false
        passportMetadata = nil
        selfieMetadata = nil
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
