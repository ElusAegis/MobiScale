import Foundation
import Combine
import CryptoKit

@MainActor
final class AttestationViewModel: ObservableObject {

    // Public state ----------------------------------------------------------
    @Published var step: Step = .idle
    @Published var progress: Double = 0            // 0…1 for ProgressView
    @Published var elapsed: TimeInterval = 0
    @Published var warning: String?                // non-nil → shows banner

    enum Step: String {
        case idle         = "Waiting to start"
        case generating   = "Generating attestation…"
        case proving      = "Proving attestation (≈120 s)…"
        case finished     = "Done ✅"
        case failed       = "Failed ❌"
    }

    // Output back to parent -------------------------------------------------
    var onCompletion: ((AttestationResult, AttestationExtProof) -> Void)?

    // Private ---------------------------------------------------------------
    private let enclave = SecureEnclaveService()
    private let prover  = ProverService()
    private var timer: Timer?
    private let expectedProveSeconds: TimeInterval = 120   // adjust if needed
    private var challenge: Data?

    // MARK: – Public API
    func run(challenge: Data) {
        guard step == .idle else { return }

        self.challenge = challenge
        step = .generating
        startTimer()

        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            // 1️⃣ Generate attestation (fast)
            let (att, usedDummy) = await self.safeGenerateAttestation(challenge: challenge)

            if usedDummy {
                await MainActor.run { self.warning = "⚠️ Fallback to dummy attestation." }
            }

            // 2️⃣ Prove (slow, ~100 s)
            await MainActor.run { self.step = .proving }
            let proof = try? await self.prover.proveAttestationExt(att: att)

            await MainActor.run {
                self.stopTimer()
                if let proof {
                    self.step = .finished
                    self.onCompletion?(att, proof)
                } else {
                    self.warning = "Attestation failed. Please try again."
                    self.step = .idle
                }
            }
        }
    }

    // MARK: – Helpers
    private func startTimer() {
        progress = 0; elapsed = 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            elapsed += 1
            if step == .proving {
                progress = min(elapsed / expectedProveSeconds, 1)
            }
        }
    }
    private func stopTimer() { timer?.invalidate(); timer = nil }

    private func safeGenerateAttestation(challenge: Data) async -> (AttestationResult, Bool) {
        do { return (try await enclave.generateAttestation(challenge: challenge), false) }
        catch { return (generateDummyAttestation(challenge: challenge), true) }
    }
}
