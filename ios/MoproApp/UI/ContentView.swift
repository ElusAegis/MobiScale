import SwiftUI

struct ContentView: View {
    @StateObject private var flow = AppFlowViewModel()

    var body: some View {
        VStack {
            switch flow.phase {
            case .introduction:
                IntroductionView {
                    flow.phase = .photoSelection
                }
            case .photoSelection:
                PhotoSelectionView { output in
                    flow.identityMatchOutput = output
                    flow.mlOutput = try? JSONEncoder().encode(output)
                    print("🔄 ML output: \(flow.mlOutput)")
                    print("🔄 Identity match output: \(flow.identityMatchOutput)")
                    print("🔄 Identity match complete")
                    flow.appendLog("Identity match complete")
                    flow.phase = .identityMatchSuccess
                }
            case .identityMatchSuccess:
                IdentityMatchSuccessView(
                    output: flow.identityMatchOutput,
                    onContinue: {
                        flow.proceedToRandomness()
                    }
                )
            case .randomness:
                RandomnessView(flow: flow) { result in
                    flow.challenge = result
                    flow.appendLog("Challenge obtained")
                    flow.phase = .attestation
                }
            case .attestation:
                AttestationView(flow: flow) { att, proof in
                    flow.attestation = (att, proof)
                    flow.appendLog("Attestation proof ready")
                    flow.phase = .assertion
                }
            case .assertion:
                AssertionView(flow: flow) { asr, comp in
                    flow.assertion = (asr, comp)
                    flow.appendLog("Assertion proof ready")
                    flow.phase = .done
                }
            case .done:
                DoneView(flow: flow)
            }
        }
        .padding()
    }
}
