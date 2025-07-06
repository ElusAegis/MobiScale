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
        VStack(spacing: 16) {

            // Pre-flight info
            Group {
                Text("🔐 Assertion Proof")
                    .font(.headline)
                Text("""
                     Next we sign a payload and build a composite proof. \
                     This step takes **about 2 minutes**.
                     """)
                    .multilineTextAlignment(.center)

                // Read-only payload display
                if let data = flow.mlOutput {
                    ScrollView(.horizontal) {
                        Text(data.hexEncodedString())
                            .font(.footnote.monospaced())
                            .textSelection(.enabled)
                            .padding(4)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(4)
                    }
                } else {
                    Text("No ML output available")
                        .foregroundColor(.secondary)
                }
            }
            .opacity(vm.step == .idle ? 1 : 0)

            // Progress area
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
                Label("Generate Assertion Proof", systemImage: "doc.plaintext")
            }
            .buttonStyle(.borderedProminent)
            .disabled(vm.step != .idle || flow.mlOutput == nil || flow.attestation == nil)
        }
        .padding()
        .onAppear { vm.onCompletion = onDone }
    }
}

// MARK: – Helpers
private extension Data {
    func hexEncodedString() -> String { map { String(format: "%02x", $0) }.joined() }
}
