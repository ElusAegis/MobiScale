import SwiftUI
import UniformTypeIdentifiers

struct DoneView: View {
    @ObservedObject var flow: AppFlowViewModel
    @State private var showingShareSheet = false
    @State private var exportData: Data?
    
    var body: some View {
        VStack(spacing: 0) {
            // Scrollable content
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Verification Complete!")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("All cryptographic proofs generated successfully")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Summary card
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "list.bullet.clipboard")
                                .foregroundColor(.blue)
                            Text("Verification Summary")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        
                        VStack(spacing: 12) {
                            VerificationStepRow(
                                number: "1",
                                title: "Identity Verification",
                                status: "✅ Complete",
                                details: "AI-powered face matching with \(Int((flow.identityMatchOutput?.score ?? 0) * 100))% confidence"
                            )
                            
                            VerificationStepRow(
                                number: "2",
                                title: "Randomness Challenge",
                                status: "✅ Complete",
                                details: "DRAND round \(flow.challenge?.meta.round ?? 0) at \(flow.challenge?.meta.fetchedAt.timeIntervalSince1970 ?? 0)"
                            )
                            
                            VerificationStepRow(
                                number: "3",
                                title: "Device Attestation",
                                status: "✅ Complete",
                                details: "Apple Secure Enclave proof generated and verified"
                            )
                            
                            VerificationStepRow(
                                number: "4",
                                title: "Data Assertion",
                                status: "✅ Complete",
                                details: "Privacy-preserving ZK proofs generated"
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Proofs section
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                                .foregroundColor(.blue)
                            Text("Generated Proofs")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        
                        VStack(spacing: 12) {
                            if let attestation = flow.attestation {
                                ProofCard(
                                    title: "Device Attestation Proof",
                                    description: "Proves device authenticity and attestation freshness",
                                    proofData: attestation.1.risc0Receipt,
                                    timestamp: Date(),
                                    icon: "shield.checkerboard"
                                )
                            }
                            
                            if let assertion = flow.assertion {
                                ProofCard(
                                    title: "Data Assertion Proof",
                                    description: "Privacy-preserving proof of verification data signature",
                                    proofData: assertion.1.risc0Receipt,
                                    timestamp: Date(),
                                    icon: "doc.text.magnifyingglass"
                                )
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Next steps
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "arrow.right.circle")
                                .foregroundColor(.blue)
                            Text("Next Steps")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        
                        VStack(spacing: 12) {
                            NextStepRow(
                                icon: "square.and.arrow.up",
                                title: "Export Proofs",
                                description: "Share your verification proofs for external validation"
                            )
                            
                            NextStepRow(
                                icon: "server.rack",
                                title: "On-chain Verification",
                                description: "Submit proofs to blockchain for permanent record"
                            )
                            
                            NextStepRow(
                                icon: "building.2",
                                title: "Enterprise Integration",
                                description: "Integrate with your organization's verification system"
                            )
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.08))
                    .cornerRadius(12)
                }
                .padding()
            }
            
            // Fixed action buttons at bottom
            VStack(spacing: 12) {
                PrimaryButton(
                    title: "Export Verification Report",
                    icon: "square.and.arrow.up",
                    color: .blue
                ) {
                    generateExportData()
                    showingShareSheet = true
                }
                
                SecondaryButton(
                    title: "View Technical Details",
                    icon: "doc.text.magnifyingglass"
                ) {
                    // Could expand to show more technical details
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: -4)
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingShareSheet) {
            if let data = exportData {
                ShareSheet(items: [data])
            }
        }
    }
    
    private func generateExportData() {
        var exportContent = """
        # Identity Verification Report
        
        **Generated:** \(Date().formatted(date: .complete, time: .complete))
        **Device:** \(UIDevice.current.model) (\(UIDevice.current.systemVersion))
        
        ## Verification Summary
        
        ### 1. Identity Verification
        - **Status:** ✅ Complete
        - **Confidence Score:** \(Int((flow.identityMatchOutput?.score ?? 0) * 100))%
        - **Model:** \(flow.identityMatchOutput?.modelId ?? "Unknown")
        - **Passport Hash:** \(flow.identityMatchOutput?.passportPhotoHash.hexString.prefix(16) ?? "N/A")...
        - **Selfie Hash:** \(flow.identityMatchOutput?.selfiePhotoHash.hexString.prefix(16) ?? "N/A")...
        
        ### 2. Randomness Challenge
        - **Status:** ✅ Complete
        - **Source:** \(flow.challenge?.meta.source ?? "Unknown")
        - **Round:** \(flow.challenge?.meta.round ?? 0)
        - **Timestamp:** \(flow.challenge?.meta.fetchedAt.timeIntervalSince1970 ?? 0)
        - **Challenge:** \(flow.challenge?.bytes.hexString ?? "N/A")
        
        ### 3. Device Attestation
        - **Status:** ✅ Complete
        - **Proof Size:** \(flow.attestation?.1.risc0Receipt.count ?? 0) bytes
        - **Type:** RISC-0 Zero-Knowledge Proof
        
        ### 4. Data Assertion
        - **Status:** ✅ Complete
        - **Proof Size:** \(flow.assertion?.1.risc0Receipt.count ?? 0) bytes
        - **Type:** Composite RISC-0 + Noir Proof
        
        ## Cryptographic Proofs
        
        ### Device Attestation Proof
        ```
        \(flow.attestation?.1.risc0Receipt.hexString ?? "No proof available")
        ```
        
        ### Data Assertion Proof
        ```
        \(flow.assertion?.1.risc0Receipt.hexString ?? "No proof available")
        ```
        
        ---
        *This report was generated by App Attester using Apple's Secure Enclave and zero-knowledge proofs for privacy-preserving identity verification.*
        """
        
        exportData = exportContent.data(using: .utf8)
    }
}

// MARK: - Verification Step Row
struct VerificationStepRow: View {
    let number: String
    let title: String
    let status: String
    let details: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.green))
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(status)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Text(details)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Proof Card
struct ProofCard: View {
    let title: String
    let description: String
    let proofData: Data
    let timestamp: Date
    let icon: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(proofData.count) bytes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text("Generated: \(timestamp.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(isExpanded ? "Show Less" : "Show Proof") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if isExpanded {
                ScrollView {
                    Text(proofData.hexString)
                        .font(.caption2.monospaced())
                        .textSelection(.enabled)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray5))
                        .cornerRadius(6)
                }
                .frame(maxHeight: 120)
                .animation(.easeInOut(duration: 0.3), value: isExpanded)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

// MARK: - Next Step Row
struct NextStepRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
