use mopro_bindings::Risc0ProofOutput;

fn main() {
    println!("Generating the execution proof for the application...");

    let Risc0ProofOutput { journal, receipt } = mopro_bindings::prove_attestation()
        .expect("Failed to run the application and generate the execution proof");

    println!("Execution proof generated successfully!");
    // The size of the journal and receipt.
    println!("Journal size: {} bytes", journal.len());
    println!("Receipt size: {} bytes", receipt.len());

    // Save the journal and receipt to files in the output directory.

    println!("Saving journal and receipt to files...");
    // Check if the output directory exists, create it if not.
    let output_dir = "output";
    std::fs::create_dir_all(&output_dir).expect("Failed to create output directory");
    // Save the journal to a file.
    let journal_path = std::path::Path::new(&output_dir).join("journal.bin");
    std::fs::write(&journal_path, journal)
        .expect("Failed to write journal to file");
    // Save the receipt to a file.
    let receipt_path = std::path::Path::new(&output_dir).join("receipt.bin");
    std::fs::write(&receipt_path, receipt)
        .expect("Failed to write receipt to file");

    println!("Journal and receipt saved to: {:?}", output_dir);
    // Print the paths to the console.
    println!("Journal path: {:?}", journal_path);
    println!("Receipt path: {:?}", receipt_path);
}