import Foundation
import CryptoKit

/// Thin wrapper around SecureEnclaveService + ProverService.
/// No @MainActor here – can be used from background tasks.
struct VerifiabilityService {
    private let enclave = SecureEnclaveService()
    private let prover  = ProverService()

    // MARK: – Attestation
    func generateAttestation(challenge: Data) async -> (AttestationResult, AttestationExtProof, Bool) {
        // Bool == usedDummy ?
        let (att, usedDummy) = await safeGenerateAttestation(challenge: challenge)
        do {
            let proof = try await prover.proveAttestationExt(att: att)
        return (att, proof, usedDummy)
        } catch ProverError.circuitNotFound(let message) {
            print("[Error] " + message)
            // Notify user via dummy proof
            let dummyProof = AttestationExtProof(risc0Receipt: Data("dummy-proof".utf8))
            return (att, dummyProof, true)
        } catch {
            let dummyProof = AttestationExtProof(risc0Receipt: Data("dummy-proof".utf8))
            return (att, dummyProof, true)
        }
    }

    // MARK: – Assertion
    func generateAssertion(payload: Data) async -> (AssertionResult, AssertionCompositeProof, Bool) {
        let (asr, usedDummy) = await safeGenerateAssertion(payload: payload)
        do {
            let comp = try await prover.proveAssertionExt(assertionResult: asr)
        return (asr, comp, usedDummy)
        } catch ProverError.circuitNotFound(let message) {
            print("[Error] " + message)
            // Notify user via dummy proof
            let dummyComp = AssertionCompositeProof(
                risc0Receipt: Data("dummy-receipt".utf8),
                noirProof: Data("dummy-noir".utf8)
            )
            return (asr, dummyComp, true)
        } catch {
            let dummyComp = AssertionCompositeProof(
                risc0Receipt: Data("dummy-receipt".utf8),
                noirProof: Data("dummy-noir".utf8)
            )
            return (asr, dummyComp, true)
        }
    }

    // ------------------------------------------------------------------
    // Private fall-back helpers
    // ------------------------------------------------------------------
    private func safeGenerateAttestation(challenge: Data) async -> (AttestationResult, Bool) {
        do { return (try await enclave.generateAttestation(challenge: challenge), false) }
        catch { return (generateDummyAttestation(challenge: challenge), true) }
    }
    private func safeGenerateAssertion(payload: Data) async -> (AssertionResult, Bool) {
        do { return (try await enclave.generateAssertion(payload: payload), false) }
        catch { return (generateDummyAssertion(payload: payload), true) }
    }
}
