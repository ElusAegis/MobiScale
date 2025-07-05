import Foundation

/// High‑level helper that chains:
///   1. `proveAttestation` (RISC‑0)
///   2. `proveAssertion`   (RISC‑0)
///   3. `generateNoirProof` (Noir/ZKP)
///
/// The output is the Noir proof `Data` ready for on‑chain / server verification.

/// Holds both the RISC‑0 receipt for the assertion *and* the Noir proof of the signature.
public struct AssertionCompositeProof: Sendable {
    public let risc0Receipt: Data
    public let noirProof: Data
}

/// Wraps the RISC-0 receipt produced by the attestation prover.
public struct AttestationExtProof: Sendable {
    public let risc0Receipt: Data
}


