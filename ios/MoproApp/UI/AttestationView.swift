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
        VStack(spacing: 16) {
            // Pre-flight description
            Group {
                Text("💡 What will happen?")
                    .font(.headline)
                Text("""
                     We’ll prove this device is genuine using Apple App Attest \
                     and a zero-knowledge proof. \
                     The proof step takes about **2 minutes**.
                     """)
                    .multilineTextAlignment(.center)
            }
            .opacity(vm.step == .idle ? 1 : 0)        // hide during run

            // Progress stack
            if vm.step != .idle {
                VStack(spacing: 8) {
                    ProgressView(vm.step.rawValue,
                                 value: vm.progress,
                                 total: 1)
                        .progressViewStyle(.linear)
                    Text("Elapsed: \(Int(vm.elapsed)) s")
                        .font(.caption.monospacedDigit())
                }
            }

            // Warning banner
            if let warn = vm.warning {
                Text(warn)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(Color.yellow.opacity(0.2))
            }

            Spacer()

            // Action button
            PrimaryButton(
                title: "Generate Attestation Proof",
                icon: "shield.checkerboard",
                color: .blue,
                isDisabled: vm.step != .idle || flow.challenge?.bytes == nil
            ) {
                if let challenge = flow.challenge?.bytes {
                    vm.run(challenge: challenge)
                }
            }
        }
        .padding()
        .onAppear { vm.onCompletion = onDone }
    }
}
