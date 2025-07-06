import SwiftUI

struct ContentView: View {
    @StateObject private var flow = AppFlowViewModel()

    var body: some View {
        VStack {
            switch flow.phase {
            case .photo:
                IdentityMatchView { result in
                    flow.mlOutput = result
                    flow.appendLog("Identity match complete")
                    flow.phase = .randomness
                }
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
