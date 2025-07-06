import Foundation
import PhotosUI
import CryptoKit
import Vision

@MainActor
final class IdentityMatchViewModel: ObservableObject {
    enum Step { case selectPassport, captureSelfie, comparing, done }

    @Published var step: Step = .selectPassport
    @Published var resultData: Data?
    @Published var error: String?

    private let modelId = "passport-selfie-v0.1"
    private let similarityThreshold: Float = 0.40   // lower = stricter match

    func processImages(passportData: Data?, selfieData: Data?, onComplete: @escaping (Data) -> Void) {
        step = .comparing
        Task {
            // Load image bytes
            guard let passportData = passportData, let selfieData = selfieData else {
                await MainActor.run {
                    self.error = "Unable to read images"
                    self.step = .selectPassport
                }
                return
            }
            // Persist the raw SHA‑256 hashes for audit purposes
            let pHash = Data(SHA256.hash(data: passportData))
            let sHash = Data(SHA256.hash(data: selfieData))

            // -------- Face‑to‑face similarity --------
            let isMatch = try FaceEmbeddingService().evaluateMatch(passport: passportData, selfie: selfieData)
            
            let output = IdentityMatchOutput(
                passportPhotoHash: pHash,
                selfiePhotoHash:   sHash,
                modelId:           modelId,
                isMatch:           isMatch
            )
            
            await MainActor.run {
                
                if output.isMatch {
                    // Match successful - proceed with attestation
                    if let json = try? JSONEncoder().encode(output) {
                        self.resultData = json
                        self.step = .done
                        onComplete(json)
                    } else {
                        self.error = "Failed to encode result"
                        self.step = .selectPassport
                    }
                } else {
                    // Match failed - reset to start
                    self.error = "Sorry, we could not quite match the photo to yourself. Please try again."
                    self.step = .selectPassport
                }
            }
        }
    }

    func resetForRetry() {
        step = .selectPassport
        error = nil
        resultData = nil
    }
} 
