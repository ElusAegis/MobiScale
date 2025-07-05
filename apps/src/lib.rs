// Copyright 2024 RISC Zero, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// This application demonstrates how to send an off-chain proof request
// to the Bonsai proving service and publish the received proofs directly
// to your deployed app contract.

// Allow unexpected cfg for the full file
#![allow(unexpected_cfgs)]

use std::time;
use methods::{ASSERTION_ELF, ATTESTATION_ELF};
use risc0_zkvm::{default_prover, ExecutorEnv, ProverOpts, VerifierContext};

mopro_ffi::app!();

#[derive(uniffi::Error, thiserror::Error, Debug)]
pub enum Risc0Error {
    #[error("Failed to prove: {0}")]
    ProveError(String),
    #[error("Failed to serialize receipt: {0}")]
    SerializeError(String),
}

#[derive(uniffi::Object)]
pub struct Risc0ProofOutput {
    pub journal: Vec<u8>,
    pub receipt: Vec<u8>,
}

#[uniffi::export]
pub fn prove_attestation() -> Result<Risc0ProofOutput, Risc0Error> {
    env_logger::init();
    // Parse CLI Arguments: The application starts by parsing command-line arguments provided by the user.

    // // Create an alloy provider for that private key and URL.
    let timestamp: i64 = time::SystemTime::now()
        .duration_since(time::UNIX_EPOCH)
        .expect("Time went backwards")
        .as_secs() as i64;
    let bytes: [u8; 8] = timestamp.to_le_bytes(); // or to_be_bytes()
    let input: &[u8] = &bytes;

    let env = ExecutorEnv::builder().write_slice(&input).build().map_err(|e| {
        Risc0Error::ProveError(format!("Failed to create ExecutorEnv: {}", e))
    })?;

    let receipt = default_prover()
        .prove_with_ctx(
            env,
            &VerifierContext::default(),
            ATTESTATION_ELF,
            &ProverOpts::fast()
        ).map_err(|e| Risc0Error::ProveError(e.to_string()))?
        .receipt;

    // Encode the seal with the selector.
    // let _seal = encode_seal(&receipt)?;

    // Extract the journal from the receipt.
    let journal_bytes = receipt.journal.bytes.clone();

    let receipt_bytes = bincode::serialize(&receipt)
        .map_err(|e| Risc0Error::SerializeError(format!("Failed to serialize receipt: {}", e)))?;

    // Return the journal and receipt as output.
    Ok(Risc0ProofOutput {
        journal: journal_bytes,
        receipt: receipt_bytes,
    })
}

#[uniffi::export]
pub fn prove_assertion() -> Result<Risc0ProofOutput, Risc0Error> {
    env_logger::init();

    let env = ExecutorEnv::builder().build().map_err(|e| {
        Risc0Error::ProveError(format!("Failed to create ExecutorEnv: {}", e))
    })?;

    let receipt = default_prover()
        .prove_with_ctx(
            env,
            &VerifierContext::default(),
            ASSERTION_ELF,
            &ProverOpts::from_max_po2(18),
        ).map_err(|e| Risc0Error::ProveError(e.to_string()))?
        .receipt;

    // Extract the journal from the receipt.
    let journal_bytes = receipt.journal.bytes.clone();

    let receipt_bytes = bincode::serialize(&receipt)
        .map_err(|e| Risc0Error::SerializeError(format!("Failed to serialize receipt: {}", e)))?;

    // Return the journal and receipt as output.
    Ok(Risc0ProofOutput {
        journal: journal_bytes,
        receipt: receipt_bytes,
    })
}
