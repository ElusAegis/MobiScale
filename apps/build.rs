use std::process::Command;
use std::path::Path;

fn main() {
    compile_noir();
}

fn compile_noir() {
    // 1. Ensure `nargo` is available in the user's PATH.
    let nargo_available = Command::new("nargo")
        .arg("--version")
        .output()
        .map(|o| o.status.success())
        .unwrap_or(false);

    if !nargo_available {
        panic!(
            "`nargo` was not found in your PATH.\n\
             Install Noir by following the quick‑start guide: \
             https://noir-lang.org/docs/getting_started/quick_start"
        );
    }

    // 2. Run `nargo compile` in the ../ecdsa folder to build the Noir proof.
    let ecdsa_dir = Path::new("../ecdsa");
    let status = Command::new("nargo")
        .arg("compile")
        .current_dir(&ecdsa_dir)
        .status()
        .expect("Failed to spawn `nargo compile`");

    if !status.success() {
        panic!("`nargo compile` failed for project at {:?}", ecdsa_dir);
    }

    // 3. Invalidate the Cargo build when anything in the ../ecdsa directory changes.
    println!("cargo:rerun-if-changed=../ecdsa");
    println!("cargo:rerun-if-changed=../ecdsa/src");
}