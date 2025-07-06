import SwiftUI

struct RandomnessView: View {
    @ObservedObject var flow: AppFlowViewModel
    @StateObject private var vm = RandomnessViewModel()
    
    // completion callback
    var onDone: (RandomnessChallenge) -> Void

    init(flow: AppFlowViewModel,
         onDone: @escaping (RandomnessChallenge) -> Void) {
        self.flow = flow
        self.onDone = onDone
        _vm = StateObject(wrappedValue: RandomnessViewModel())
    }

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "dice.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Randomness Challenge")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Fetch cryptographic randomness from DRAND")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Explanation card
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("What is DRAND?")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("DRAND provides cryptographically secure randomness for device attestation.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        
                        Spacer()
                    }
                    
                    HStack(spacing: 12) {
                        FeatureBadge(icon: "shield.checkerboard", text: "Secure")
                        FeatureBadge(icon: "globe", text: "Decentralized")
                        FeatureBadge(icon: "checkmark.seal", text: "Verifiable")
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.08))
                .cornerRadius(12)
            }
            
            // Main content area
            switch vm.step {
            case .idle:
                FetchChallengeView(onFetch: { vm.fetch() })
                
            case .fetching:
                FetchingChallengeView()
                
            case .done:
                if let challenge = vm.challenge {
                    ChallengeResultView(
                        challenge: challenge,
                        onGenerateAttestation: {
                            onDone(challenge)
                        }
                    )
                }
                
            case .failed:
                FetchErrorView(
                    error: vm.error ?? "Unknown error",
                    onRetry: { vm.step = .idle }
                )
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Fetch Challenge View
struct FetchChallengeView: View {
    let onFetch: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                
                Text("Ready to Fetch Challenge")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Tap the button below to fetch a random challenge from the DRAND network. This will be used to prove your device's authenticity.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            PrimaryButton(
                title: "Fetch from DRAND",
                icon: "network",
                color: .blue
            ) {
                onFetch()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Fetching Challenge View
struct FetchingChallengeView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "network")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: isAnimating)
                
                Text("Fetching Challenge...")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Connecting to DRAND network to get cryptographically secure randomness")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            ProgressView()
                .scaleEffect(1.2)
                .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Challenge Result View
struct ChallengeResultView: View {
    let challenge: RandomnessChallenge
    let onGenerateAttestation: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Success indicator
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)
                
                Text("Challenge Retrieved!")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            
            // Challenge details
            VStack(spacing: 16) {
                ChallengeDetailRow(
                    title: "Source",
                    value: challenge.meta.source,
                    icon: "network"
                )
                
                ChallengeDetailRow(
                    title: "Round",
                    value: "\(challenge.meta.round)",
                    icon: "number.circle"
                )
                
                ChallengeDetailRow(
                    title: "Fetched At",
                    value: "\(Int(challenge.meta.fetchedAt.timeIntervalSince1970))",
                    icon: "clock"
                )
                
                // Challenge bytes
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(.blue)
                        Text("Challenge Bytes")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    
                    Text(challenge.bytes.hexString)
                        .font(.caption.monospaced())
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                        .textSelection(.enabled)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Attestation explanation
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "shield.checkerboard")
                        .foregroundColor(.blue)
                    Text("This challenge will be used to attest your device's authenticity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .padding(.horizontal, 4)
            
            // Generate attestation button
            PrimaryButton(
                title: "Generate Device Attestation",
                icon: "shield.checkerboard",
                color: .green
            ) {
                onGenerateAttestation()
            }
        }
    }
}

// MARK: - Fetch Error View
struct FetchErrorView: View {
    let error: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.red)
                
                Text("Fetch Failed")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            PrimaryButton(
                title: "Try Again",
                icon: "arrow.clockwise",
                color: .blue
            ) {
                onRetry()
            }
        }
        .padding()
        .background(Color.red.opacity(0.08))
        .cornerRadius(16)
    }
}



struct ChallengeDetailRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .fontDesign(.monospaced)
        }
    }
}
