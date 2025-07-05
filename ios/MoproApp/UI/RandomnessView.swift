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
        VStack(spacing: 16) {

            Text("🪙 League-of-Entropy Challenge")
                .font(.headline)

            switch vm.step {
            case .idle:
                Button("Fetch Random Challenge") { vm.fetch() }
                    .buttonStyle(.borderedProminent)

            case .fetching:
                ProgressView("Contacting drand …")

            case .done:
                if let c = vm.challenge {
                    VStack(spacing: 8) {
                        Text("Round \(c.meta.round)")
                        Text(c.bytes.hexString)         // utility ext. below
                            .font(.footnote.monospaced())
                            .padding(4)
                            .background(.secondary.opacity(0.1))
                            .cornerRadius(4)
                        Button("Use This Challenge") {
                            flow.setChallenge(c)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

            case .failed:
                VStack {
                    Text("Failed: \(vm.error ?? "unknown")").foregroundColor(.red)
                    Button("Retry") { vm.step = .idle }
                }
            }

            Spacer()
        }
        .padding()
        .onAppear { if vm.step == .idle { vm.fetch() } }
    }
}
