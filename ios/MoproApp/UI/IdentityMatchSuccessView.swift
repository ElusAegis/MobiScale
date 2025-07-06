import SwiftUI

struct IdentityMatchSuccessView: View {
    let output: IdentityMatchOutput?
    let onContinue: () -> Void
    
    private var score: Float {
        output?.score ?? 0.0
    }
    
    private var modelId: String {
        output?.modelId ?? "unknown"
    }
    
    private func formatHash(_ data: Data?) -> String {
        guard let data = data else { return "N/A" }
        let hexString = data.hexString
        let prefix = String(hexString.prefix(16))
        return "\(prefix)..."
    }
    
    private var confidenceLevel: String {
        switch score {
        case 0.9...: return "Excellent"
        case 0.8..<0.9: return "Very Good"
        case 0.7..<0.8: return "Good"
        default: return "Acceptable"
        }
    }
    
    private var confidenceColor: Color {
        switch score {
        case 0.9...: return .green
        case 0.8..<0.9: return .blue
        case 0.7..<0.8: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Scrollable content
            ScrollView {
                VStack(spacing: 20) {
                    // Header - Compact
                    VStack(spacing: 6) {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        
                        Text("Identity Verified!")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Passport matched to selfie")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Match Results - Keep prominent
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "face.smiling")
                                .foregroundColor(.blue)
                            Text("Match Confidence")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        VStack(spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Score")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(confidenceLevel)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(confidenceColor)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("Percentage")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(Int(score * 100))%")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(confidenceColor)
                                }
                            }
                            
                            ProgressView(value: score, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle(tint: confidenceColor))
                                .scaleEffect(y: 1.5)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Compact Details
                    DisclosureGroup {
                        VStack(spacing: 8) {
                            DetailRow(title: "AI Model", value: modelId)
                            DetailRow(title: "Passport Hash", value: formatHash(output?.passportPhotoHash))
                            DetailRow(title: "Selfie Hash", value: formatHash(output?.selfiePhotoHash))
                        }
                        .padding(.top, 8)
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                                .foregroundColor(.blue)
                            Text("Technical Details")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Compact Security Notice
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "shield.checkerboard")
                            .foregroundColor(.blue)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ready for Attestation")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("Your verification will be cryptographically attested using Apple's Secure Enclave.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
            
            // Fixed button at bottom
            VStack(spacing: 8) {
                PrimaryButton(
                    title: "Generate Device Attestation",
                    icon: "lock.shield.fill",
                    color: .blue
                ) {
                    onContinue()
                }
                
                Text("Proves verification on genuine iPhone")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: -4)
        }
        .background(Color.clear)
        .navigationBarHidden(true)
    }
}


