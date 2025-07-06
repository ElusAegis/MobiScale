import SwiftUI

struct AttestationView: View {
    @ObservedObject var flow: AppFlowViewModel
    @StateObject private var vm = AttestationViewModel()

    // Expose completion to parent (via initializer)
    var onDone: (AttestationResult, AttestationExtProof) -> Void

    init(flow: AppFlowViewModel, onDone: @escaping (AttestationResult, AttestationExtProof) -> Void) {
        self.flow = flow
        self.onDone = onDone
    }

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "shield.checkerboard")
                        .font(.title)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Device Attestation")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Prove this device is genuine using Apple's Secure Enclave")
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
                            Text("What is Device Attestation?")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("Apple's Secure Enclave creates a cryptographic proof that this device is genuine and hasn't been tampered with. This proves the device authenticity and that the attestation is not stale.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        
                        Spacer()
                    }
                    
                    HStack(spacing: 8) {
                        FeatureBadge(icon: "iphone", text: "Genuine")
                        FeatureBadge(icon: "clock", text: "Fresh")
                        FeatureBadge(icon: "lock.shield", text: "Secure")
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.08))
                .cornerRadius(12)
            }
            
            // Main content area
            switch vm.step {
            case .idle:
                AttestationReadyView(onStart: {
                    if let challenge = flow.challenge?.bytes {
                        vm.run(challenge: challenge)
                    }
                })
                
            case .generating:
                GeneratingAttestationView()
                
            case .proving:
                ProvingAttestationView(
                    progress: vm.progress,
                    elapsed: vm.elapsed
                )
                
            case .finished:
                AttestationSuccessView(
                    onContinue: {
                        // This will be handled by the completion callback
                    },
                    usedDummy: vm.warning?.contains("dummy") == true
                )
                
            case .failed:
                AttestationErrorView(
                    error: vm.warning ?? "Attestation failed",
                    onRetry: {
                        vm.step = .idle
                    }
                )
            }
            
            Spacer()
        }
        .padding()
        .onAppear { vm.onCompletion = onDone }
    }
}

// MARK: - Attestation Ready View
struct AttestationReadyView: View {
    let onStart: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "iphone.gen3")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                
                Text("Ready to Attest Device")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("This will generate a cryptographic proof that your device is genuine and hasn't been tampered with.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Process steps preview
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "list.bullet.clipboard")
                        .foregroundColor(.blue)
                    Text("Process Overview")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                VStack(spacing: 12) {
                    ProcessStepRow(
                        number: "1",
                        title: "Generate Attestation",
                        description: "Create device proof using Secure Enclave",
                        duration: "~5 seconds",
                        icon: "iphone.gen3"
                    )
                    
                    ProcessStepRow(
                        number: "2", 
                        title: "Prove Attestation",
                        description: "Verify attestation is valid and not stale",
                        duration: "~2 minutes",
                        icon: "checkmark.shield"
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            PrimaryButton(
                title: "Start Device Attestation",
                icon: "shield.checkerboard",
                color: .blue
            ) {
                onStart()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Generating Attestation View
struct GeneratingAttestationView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "iphone.gen3")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                
                Text("Generating Device Attestation...")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Creating cryptographic proof using Apple's Secure Enclave")
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

// MARK: - Proving Attestation View
struct ProvingAttestationView: View {
    let progress: Double
    let elapsed: TimeInterval
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.shield")
                    .font(.system(size: 48))
                    .foregroundColor(.green)
                
                Text("Proving Attestation...")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Verifying device attestation is valid and not stale")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    .scaleEffect(y: 1.5)
                
                HStack {
                    Text("Elapsed: \(Int(elapsed))s")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption.monospacedDigit())
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Technical info
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "cpu")
                        .foregroundColor(.blue)
                        .font(.caption)
                    
                    Text("RISC-0 zero-knowledge proof generation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .foregroundColor(.orange)
                        .font(.caption)
                    
                    Text("This step takes about 2 minutes to complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 4)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Attestation Success View
struct AttestationSuccessView: View {
    let onContinue: () -> Void
    let usedDummy: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)
                
                Text("Device Attestation Complete!")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(.green)
                    Text("Device proven genuine")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "clock.badge.checkmark")
                        .foregroundColor(.green)
                    Text("Attestation verified as fresh")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.green)
                    Text("Cryptographic proof generated")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
            
            // Next step explanation
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.right.circle")
                        .foregroundColor(.blue)
                    Text("Ready for the final step: assertion proof generation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                if usedDummy {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                            .font(.caption2)
                        Text("Fallback to dummy attestation used")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Attestation Error View
struct AttestationErrorView: View {
    let error: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.red)
                
                Text("Attestation Failed")
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

// MARK: - Process Step Row
struct ProcessStepRow: View {
    let number: String
    let title: String
    let description: String
    let duration: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.blue))
            
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(duration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .cornerRadius(4)
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}
