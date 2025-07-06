import Foundation
import PhotosUI
import CryptoKit

@MainActor
final class IdentityMatchViewModel: ObservableObject {
    enum Step { case selectPassport, captureSelfie, comparing, done }

    @Published var step: Step = .selectPassport
    @Published var resultData: Data?
    @Published var error: String?

    private let modelId = "passport-selfie-v0.1"

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
            // Placeholder ML model: compare SHA-256 hashes equality
            let pHash = Data(SHA256.hash(data: passportData))
            let sHash = Data(SHA256.hash(data: selfieData))
            let decision = (pHash == sHash) // obviously false in real life – placeholder

            let output = IdentityMatchOutput(
                passportPhotoHash: pHash,
                selfiePhotoHash: sHash,
                modelId: modelId,
                match: decision
            )
            
            await MainActor.run {
                if decision {
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
