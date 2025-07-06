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
    private let similarityThreshold: Float = 0.70   // ArcFace w600k_r50 recommended

    func processImages(passportData: Data?, selfieData: Data?, onComplete: @escaping (Data) -> Void) {
        step = .comparing
        Task {
            // --- 0. Byte check -------------------------------------------------
            guard let passportData = passportData, let selfieData = selfieData else {
                await MainActor.run {
                    self.error = "Unable to read images"
                    self.step  = .selectPassport
                }
                return
            }

            // --- 1. Audit SHA‑256 fingerprints --------------------------------
            let pHash = Data(SHA256.hash(data: passportData))
            let sHash = Data(SHA256.hash(data: selfieData))

            // --- 2. Face embeddings  ------------------------------------------
            var svc = FaceEmbeddingService()
            let passportVec: [Float]
            do {
                passportVec = try svc.embedding(from: passportData)
            } catch {
                await MainActor.run {
                    self.error = "No face detected in the passport photo. Please choose a clearer image."
                    self.step  = .selectPassport
                }
                return
            }

            let selfieVec: [Float]
            do {
                selfieVec = try svc.embedding(from: selfieData)
            } catch {
                await MainActor.run {
                    self.error = "No face detected in the selfie image. Please retake your selfie."
                    self.step  = .selectPassport
                }
                return
            }

            // --- 3. Similarity & decision -------------------------------------
            let cosine  = svc.cosine(passportVec, selfieVec)
            print("🧠 Cosine similarity:", cosine)

            let output = IdentityMatchOutput(
                passportPhotoHash: pHash,
                selfiePhotoHash:   sHash,
                modelId:           modelId,
                score:             cosine
            )

            // --- 4. UI update --------------------------------------------------
            await MainActor.run {
                if output.score >= similarityThreshold {
                    if let json = try? JSONEncoder().encode(output) {
                        self.resultData = json
                        self.step       = .done
                        onComplete(json)
                    } else {
                        self.error = "Failed to encode result"
                        self.step  = .selectPassport
                    }
                } else {
                    self.error = "Sorry, the two faces don’t appear to match. Please try again."
                    self.step  = .selectPassport
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
