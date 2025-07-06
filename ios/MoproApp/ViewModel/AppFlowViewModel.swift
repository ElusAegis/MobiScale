import Foundation

@MainActor
final class AppFlowViewModel: ObservableObject {

    enum Phase { case introduction, photoSelection, identityMatchSuccess, randomness, attestation, assertion, done }

    // MARK: – Public state
    @Published var phase: Phase = .assertion
    @Published var log: String  = "Ready"
    @Published var warning: String?

    // Final artefacts 
    var mlOutput: Data? = Data(base64Encoded: "eyJpZCI6IjEiLCJ0eXBlIjoiY29kZSIsImNvZGUiOiJjb2RlIn0=") // TODO - remove this
    var identityMatchOutput: IdentityMatchOutput?
    var challenge: RandomnessChallenge?
    var attestation:   (AttestationResult, AttestationExtProof)?
    var assertion:     (AssertionResult, AssertionCompositeProof)?

    // Service
    private let service = VerifiabilityService()

    // Convenience
    func appendLog(_ s: String) { log.append("\n" + s) }

    // Helper to show temporary warnings
    func showWarning(_ msg: String, for seconds: TimeInterval = 6) {
        warning = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in self?.warning = nil }
    }

    // MARK: – Bridge methods the child views can call
    
    func setChallenge(_ c: RandomnessChallenge) {
        challenge = c
        appendLog("Received LoE challenge – round \(c.meta.round)")
        phase = .attestation
    }
    
    func proceedToRandomness() {
        phase = .randomness
    }

    func runAssertion() async -> Bool {
        guard let payload = mlOutput else { 
            appendLog("❌ No ML output available for assertion")
            return false 
        }

        print("🔄 AppFlowViewModel: Running assertion with \(payload.count) bytes of data")
        
        do {
            let (asr, comp, usedDummy) = await service.generateAssertion(payload: payload)
            if usedDummy { showWarning("⚠️ Dummy assertion used") }

            assertion = (asr, comp)
            appendLog("Assertion done – final proof \(comp.noirProof.count + comp.risc0Receipt.count) bytes")
            return true
        } catch {
            appendLog("❌ Assertion failed: \(error.localizedDescription)")
            return false
        }
    }
}
