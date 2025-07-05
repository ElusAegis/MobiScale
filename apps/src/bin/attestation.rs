use mopro_bindings::Risc0ProofOutput;

fn main() {
    println!("Generating the execution proof for the application...");

    let Risc0ProofOutput { receipt } = mopro_bindings::prove_attestation()
        .expect("Failed to run the application and generate the execution proof");

    println!("Execution proof generated successfully!");
    // The size of the receipt.
    println!("Receipt size: {} bytes", receipt.len());

    // Save the receipt to files in the output directory.

    println!("Saving journal and receipt to files...");
    // Check if the output directory exists, create it if not.
    let output_dir = "output";
    std::fs::create_dir_all(&output_dir).expect("Failed to create output directory");
    // Save the journal to a file.
    let receipt_path = std::path::Path::new(&output_dir).join("receipt.bin");
    std::fs::write(&receipt_path, receipt)
        .expect("Failed to write receipt to file");

    println!("Journal and receipt saved to: {:?}", output_dir);
    // Print the paths to the console.
    println!("Receipt path: {:?}", receipt_path);
}