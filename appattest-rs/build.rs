//! build.rs – downloads Apple’s App Attest root **PEM**, converts to **DER**, and
//! stores both in `certificates/`.

use std::{fs, path::Path, process::exit, time::Duration};
use base64::Engine;
use base64::engine::general_purpose;

/// Remote Apple PEM (never changes).
const PEM_URL: &str =
    "https://www.apple.com/certificateauthority/Apple_App_Attestation_Root_CA.pem";

/// Local paths.
const CERT_DIR: &str = "certificates";
const PEM_PATH: &str = "certificates/Apple_App_Attestation_Root_CA.pem";
const DER_PATH: &str = "certificates/Apple_App_Attestation_Root_CA.der";

fn main() {
    // Re-run when this script or the generated DER changes
    println!("cargo:rerun-if-changed=build.rs");
    println!("cargo:rerun-if-changed={DER_PATH}");

    // Fetch + convert only if DER is missing
    if Path::new(DER_PATH).exists() {
        return;
    }

    // Ensure the target directory exists
    fs::create_dir_all(CERT_DIR).expect("failed to create certificates/ directory");

    // Download PEM
    let pem_bytes = match fetch_pem(PEM_URL) {
        Ok(b) => b,
        Err(e) => {
            eprintln!("❌  {e}");
            exit(1);
        }
    };

    // Save PEM for reference/debugging
    fs::write(PEM_PATH, &pem_bytes).expect("unable to write PEM file");

    // Convert to DER and save
    let der_bytes = match pem_to_der(&pem_bytes) {
        Ok(b) => b,
        Err(e) => {
            eprintln!("❌  PEM → DER conversion failed: {e}");
            exit(1);
        }
    };
    fs::write(DER_PATH, der_bytes).expect("unable to write DER file");
}

/// Download the PEM as raw bytes.
fn fetch_pem(url: &str) -> Result<Vec<u8>, Box<dyn std::error::Error>> {
    let client = reqwest::blocking::Client::builder()
        .timeout(Duration::from_secs(15))
        .build()?;

    let resp = client.get(url).send()?;
    if !resp.status().is_success() {
        return Err(format!("HTTP error: {}", resp.status()).into());
    }

    Ok(resp.bytes()?.to_vec())
}

/// Strip PEM headers/footers and base64-decode the body.
fn pem_to_der(pem: &[u8]) -> Result<Vec<u8>, Box<dyn std::error::Error>> {
    let pem_str = std::str::from_utf8(pem)?;
    let b64: String = pem_str
        .lines()
        .filter(|l| !l.starts_with("-----")) // skip BEGIN/END lines
        .collect();
    Ok(general_purpose::STANDARD.decode(b64.trim())?)
}
