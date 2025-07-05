import SwiftUI

struct ContentView: View {
    @StateObject private var vm = ProofViewModel()

    var body: some View {
        VStack(spacing: 20) {

            Text("App Attest Prototype")
                .font(.title)

            ScrollView {
                Text(vm.log)
                    .font(.caption2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 120)

            if let payload = vm.randomPayloadString {
                Text("Payload: \(payload)")
                    .font(.caption)
            }

            if vm.isRunning {
                Text("⏱ \(Int(vm.elapsed)) s")
                    .font(.caption)
            }

            HStack {
                Button("Generate Attestation")  { vm.generateAttestation() }
                    .disabled(vm.isRunning)

                Button("Generate Assertion")    { vm.generateAssertion() }
                    .disabled(vm.isRunning || vm.attestationResult == nil)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
