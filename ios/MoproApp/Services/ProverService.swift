//
//  ProverService.swift
//  MoproApp
//
//  Created by Artem Grigor on 05/07/2025.
//

import Foundation
import CryptoKit

/// High‑level helper that chains:
///   1. `proveAttestation` (RISC‑0)
///   2. `proveAssertion`   (RISC‑0)
///   3. `generateNoirProof` (Noir/ZKP)
///
/// The output is the Noir proof `Data` ready for on‑chain / server verification.
public actor ProverService {


    /// Path of "ecdsa.json" bundled with the app. Returns nil if missing.
    private var circuitPath: String? {
        guard let url = Bundle.main.url(forResource: "ecdsa", withExtension: "json") else {
            return nil
        }
        return url.path
    }

    /// Generate a full proof pipeline for the given assertion result.
    ///
    /// 1. Runs `proveAssertion` to obtain an `AssertionProofOutput`.
    /// 2. Prepends the SHA‑256 hash of `assertionResult.payload` to the Noir inputs.
    /// 3. Flattens the signature + assertion hash into `[String]` inputs.
    /// 4. Produces a Noir proof (`Data`) via `generateNoirProof`.
    ///
    /// - Returns: Raw Noir proof bytes.
    public func proveAssertionExt(assertionResult: AssertionResult) async throws -> AssertionCompositeProof {

        // RISC‑0 proof for the iOS‑level assertion (signature)
        let assertionProof = try proveAssertion()

        // 1️⃣  Hash of the original payload (32 bytes) — must be the first Noir input
        let payloadHash = SHA256.hash(data: assertionResult.payload)
        var byteBuffer: [UInt8] = Array(payloadHash)

        let sig = assertionProof.signatureData
        byteBuffer.append(contentsOf: sig.signatureR)
        byteBuffer.append(contentsOf: sig.signatureS)
        byteBuffer.append(contentsOf: sig.publicKeyX)
        byteBuffer.append(contentsOf: sig.publicKeyY)

        let noirInputs = byteBuffer.map { String($0) }

        // 3️⃣ — Noir signature proof ----------------------------------------------------
        guard let circuitPath = circuitPath else {
            throw ProverError.circuitNotFound("ecdsa.json not found in app bundle")
        }
        let noirProof = try generateNoirProof(
            circuitPath: circuitPath,
            srsPath: nil,
            inputs: noirInputs
        )

        return AssertionCompositeProof(risc0Receipt: assertionProof.proof.receipt, noirProof: noirProof)
    }
    
    /// Runs the RISC-0 circuit that proves the App-Attest attestation.
    /// - Parameter att: The `AttestationResult` returned from `SecureEnclaveService.generateAttestation`.
    /// - Returns: `AttestationProof` (just the receipt bytes).
    public func proveAttestationExt(att: AttestationResult) throws -> AttestationExtProof {

   
        let proofOut = try proveAttestation()

        return AttestationExtProof(risc0Receipt: proofOut.receipt)
    }
}

public enum ProverError: Error {
    case circuitNotFound(String)
}
