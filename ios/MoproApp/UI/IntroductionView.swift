import SwiftUI

struct IntroductionView: View {
    let onStart: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Scrollable content
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "shield.checkerboard")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("App Attester")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Cryptographic Identity Verification")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Main explanation
                    VStack(spacing: 20) {
                        FeatureCard(
                            icon: "person.crop.circle.badge.checkmark",
                            title: "AI-Powered Identity Verification",
                            description: "Compare your passport photo with a live selfie using advanced facial recognition technology. Our AI model ensures accurate identity matching with high confidence scores."
                        )
                        
                        FeatureCard(
                            icon: "lock.shield.fill",
                            title: "Device Security Attestation",
                            description: "Sign sensitive verification data with your iPhone's Secure Enclave to prove authenticity."
                        )
                        
                        FeatureCard(
                            icon: "doc.text.magnifyingglass",
                            title: "Zero-Knowledge Proofs",
                            description: "Prove computations were done correctly without exposing sensitive data like image hashes and confidence scores. ZK enables private, non-interactive verification with compressed proofs."
                        )
                    }
                    
                    // Process overview
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "list.bullet.clipboard")
                                .foregroundColor(.blue)
                            Text("How It Works")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        
                        VStack(spacing: 12) {
                            ProcessStep(number: "1", title: "Photo Verification", description: "Upload passport and take selfie")
                            ProcessStep(number: "2", title: "AI Comparison", description: "Advanced model analyzes facial features")
                            ProcessStep(number: "3", title: "Device Attestation", description: "Sign verification data with Secure Enclave")
                            ProcessStep(number: "4", title: "ZK Proof Generation", description: "Hide sensitive data while proving computations")
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Security notice
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Privacy First")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("Your photos and verification data are processed locally. ZK proofs allow you to prove identity verification without exposing sensitive information like image hashes or confidence scores.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
            
            // Fixed button at bottom
            VStack(spacing: 8) {
                PrimaryButton(
                    title: "Start Verification",
                    icon: "arrow.right.circle.fill",
                    color: .blue
                ) {
                    onStart()
                }
                
                Text("Takes about 5 minutes to complete")
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

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ProcessStep: View {
    let number: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.blue))
            
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