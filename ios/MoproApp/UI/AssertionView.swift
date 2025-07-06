import SwiftUI

struct AssertionView: View {
    @ObservedObject var flow: AppFlowViewModel
    @StateObject private var vm: AssertionViewModel

    // completion callback
    var onDone: (AssertionResult, AssertionCompositeProof) -> Void

    init(flow: AppFlowViewModel,
         onDone: @escaping (AssertionResult, AssertionCompositeProof) -> Void) {
        self.flow = flow
        self.onDone = onDone
        _vm = StateObject(wrappedValue: AssertionViewModel(flow: flow))
    }

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.title)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Data Assertion")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Sign verification data and generate privacy-preserving proofs")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
            //     // Explanation card
            //     VStack(spacing: 12) {
            //         HStack(spacing: 12) {
            //             Image(systemName: "info.circle.fill")
            //                 .foregroundColor(.blue)
            //                 .font(.title3)
                        
            //             VStack(alignment: .leading, spacing: 6) {
            //                 Text("What is Data Assertion?")
            //                     .font(.headline)
            //                     .fontWeight(.semibold)
                            
            //                 Text("Your device will cryptographically sign the verification data, guaranteeing it came from a secure device. ZK proofs preserve privacy while proving the signature is valid.")
            //                     .font(.subheadline)
            //                     .foregroundColor(.secondary)
            //                     .multilineTextAlignment(.leading)
            //             }
                        
                    //     Spacer()
                    // }
                    
            //         HStack(spacing: 8) {
            //             FeatureBadge(icon: "signature", text: "Signed")
            //             FeatureBadge(icon: "eye.slash", text: "Private")
            //             FeatureBadge(icon: "checkmark.shield", text: "Verified")
            //         }
            //     }
            //     .padding()
            //     .background(Color.blue.opacity(0.08))
            //     .cornerRadius(12)
            }
            
            // Main content area
            switch vm.step {
            case .idle:
                AssertionReadyView(
                    payloadData: flow.mlOutput,
                    onStart: {
                        vm.run()
                    }
                )
                
            case .generating:
                GeneratingAssertionView(
                    progress: vm.progress,
                    elapsed: vm.elapsed
                )
                
            case .finished:
                AssertionSuccessView(
                    onContinue: {
                        // This will be handled by the completion callback
                    },
                    usedDummy: vm.warning?.contains("dummy") == true
                )
                
            case .failed:
                AssertionErrorView(
                    error: vm.warning ?? "Assertion failed",
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

// MARK: - Assertion Ready View
struct AssertionReadyView: View {
    let payloadData: Data?
    let onStart: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                
                Text("Ready to Assert Data")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("This will sign your verification data and generate privacy-preserving zero-knowledge proofs.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Data to be asserted
            if let data = payloadData {
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.blue)
                        Text("Data to be Asserted")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    DataDisplayView(data: data)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
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
                        title: "Sign Data",
                        description: "Cryptographically sign verification data",
                        duration: "~5 seconds",
                        icon: "signature"
                    )
                    
                    ProcessStepRow(
                        number: "2", 
                        title: "Generate ZK Proofs",
                        description: "RISC-0 + Noir proofs for privacy",
                        duration: "~2 minutes",
                        icon: "eye.slash"
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            PrimaryButton(
                title: "Start Data Assertion",
                icon: "doc.text.magnifyingglass",
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

// MARK: - Data Display View
struct DataDisplayView: View {
    let data: Data
    @State private var isExpanded = false
    
    private var displayText: String {
        // Try to parse as JSON first
        if let json = try? JSONSerialization.jsonObject(with: data),
           let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let jsonString = String(data: prettyData, encoding: .utf8) {
            return jsonString
        }
        
        // Fallback to hex representation
        return data.hexString
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Payload")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button(isExpanded ? "Hide" : "Show") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if isExpanded {
                ScrollView {
                    Text(displayText)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                }
                .frame(maxHeight: 200)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Generating Assertion View
struct GeneratingAssertionView: View {
    let progress: Double
    let elapsed: TimeInterval
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                
                Text("Generating Assertion Proofs...")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Signing data and building privacy-preserving zero-knowledge proofs")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(y: 1.5)
                
                HStack {
                    Text("Elapsed: \(Int(elapsed))s")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption.monospacedDigit())
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Technical info
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "signature")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    Text("Device signature generation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "cpu")
                        .foregroundColor(.blue)
                        .font(.caption)
                    
                    Text("RISC-0 zero-knowledge proof")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "eye.slash")
                        .foregroundColor(.purple)
                        .font(.caption)
                    
                    Text("Noir signature proof for privacy")
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

// MARK: - Assertion Success View
struct AssertionSuccessView: View {
    let onContinue: () -> Void
    let usedDummy: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)
                
                Text("Data Assertion Complete!")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "signature")
                        .foregroundColor(.green)
                    Text("Data cryptographically signed")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "eye.slash")
                        .foregroundColor(.green)
                    Text("Privacy-preserving proofs generated")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(.green)
                    Text("Verification data secured")
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
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("All verification steps completed successfully!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                if usedDummy {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                            .font(.caption2)
                        Text("Fallback to dummy assertion used")
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

// MARK: - Assertion Error View
struct AssertionErrorView: View {
    let error: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.red)
                
                Text("Assertion Failed")
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
