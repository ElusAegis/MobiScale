import SwiftUI

struct AttestationView: View {
    @StateObject private var vm = AttestationViewModel()

    // Expose completion to parent (via initializer)
    var onDone: (AttestationResult, AttestationExtProof) -> Void

    init(onDone: @escaping (AttestationResult, AttestationExtProof) -> Void) {
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
            Button {
                vm.run()
            } label: {
                Label("Generate Attestation Proof", systemImage: "shield.checkerboard")
            }
            .buttonStyle(.borderedProminent)
            .disabled(vm.step != .idle)
        }
        .padding()
        .onAppear { vm.onCompletion = onDone }
    }
}
