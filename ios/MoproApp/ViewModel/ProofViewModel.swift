import Foundation
import Combine
import CryptoKit

@MainActor
final class ProofViewModel: ObservableObject {

    // MARK: -- Public state
    @Published var log: String = "Ready"
    @Published var isRunning = false
    @Published var elapsed: TimeInterval = 0
    @Published var randomPayloadString: String?

    // MARK: -- Cached artifacts
    var attestationResult: AttestationResult?
    var attestationProof: AttestationExtProof?
    var assertionResult: AssertionResult?
    var assertionCompositeProof: AssertionCompositeProof?

    // MARK: -- Private
    private var timer: Timer?
    private let enclave = SecureEnclaveService()
    private let prover  = ProverService()

    // MARK: -- UI actions
    func generateAttestation() {
        guard !isRunning else { return }

        start()
        Task.detached(priority: .userInitiated) { [weak self] in
            do {
                // 32-byte random challenge
                let challenge = Data((0..<32).map { _ in UInt8.random(in: 0...255) })

                // 1️⃣ Attestation & RISC-0 proof
                let att = try await self?.enclave.generateAttestation(challenge: challenge)
                let rec = try await self?.prover.proveAttestationExt(att: att!)
                
                await self?.storeAttestation(att, proof: rec)
                await self?.finish("✅ Attestation OK (\(rec?.risc0Receipt.count ?? 0) bytes)")
            } catch {
                await self?.finish("❌ Attestation: \(error.localizedDescription)")
            }
        }
    }

    func generateAssertion() {
        guard !isRunning, let att = attestationResult else { return }

        start()
        Task.detached(priority: .userInitiated) { [weak self] in
            do {
                // Random payload (show it later)
                let payloadString = UUID().uuidString
                let payload = Data(payloadString.utf8)

                // 2️⃣ Assertion (sign payload) & composite proof
                let asr = try await self?.enclave.generateAssertion(payload: payload)
                let comp = try await self?.prover.proveAssertionExt(assertionResult: asr!)

                await self?.storeAssertion(asr, composite: comp, payloadString: payloadString)
                await self?.finish("✅ Full proof OK (Noir \(comp?.noirProof.count ?? 0) B)")
            } catch {
                await self?.finish("❌ Assertion: \(error.localizedDescription)")
            }
        }
    }

    // MARK: -- Helpers
    private func start() {
        log = "⏳ Running…"
        isRunning = true
        elapsed = 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.elapsed += 1
            }
        }
    }

    private func finish(_ message: String) {
        timer?.invalidate()
        timer = nil
        log = message
        isRunning = false
    }

    private func storeAttestation(_ att: AttestationResult?, proof: AttestationExtProof?) {
        attestationResult = att
        attestationProof = proof
    }

    private func storeAssertion(
        _ asr: AssertionResult?,
        composite: AssertionCompositeProof?,
        payloadString: String
    ) {
        assertionResult = asr
        assertionCompositeProof = composite
        randomPayloadString = payloadString
    }
}
