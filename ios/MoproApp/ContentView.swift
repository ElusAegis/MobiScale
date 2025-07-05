import SwiftUI
import DeviceCheck
import CryptoKit
import Foundation

import Security   // add at top of the file


struct ContentView: View {
    @State private var log = "App Attest Loaded"
    @State private var keyID: String? = nil     // ← used by assertion step
    // State for proof execution
    @State private var isRunningProof = false
    @State private var proofElapsed: TimeInterval = 0
    @State private var proofTimer: Timer? = nil

    var body: some View {
        VStack(spacing: 24) {
            Text("App Attest Demo")
                .font(.title)

            Text(log)
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding()

            if isRunningProof {
                Text("⏱️ Proof running: \(Int(proofElapsed)) s")
                    .font(.caption)
            }

            Button("Run Proof") {
                Task {
                    await startProof()
                }
            }
            .disabled(isRunningProof)
            
            Button("Fetch Challenge") {
                Task {
                    do {
                        let info = try await RandomnessProvider.fetchLoEChallenge()
                        log = """
                        ✅ Challenge fetched
                        • Source : \(info.source)
                        • Round  : \(info.round)
                        • Time   : \(info.fetchedAt)
                        • Challenge (hex): \(info.challenge32Hex)
                        """
                    } catch {
                        log = "❌ Failed to fetch challenge: \(error)"
                    }
                }
            }
            .disabled(isRunningProof)

            Button("Run Noir") {
                Task {
                    guard let circuitPath = Bundle.main.path(forResource: "ecdsa", ofType: "json") else {
                        log = "❌ ecdsa circuit not found in bundle."
                        return
                    }

                    isRunningProof = true
                    proofElapsed = 0
                    startTimer()

                    do {
                        // === Step 1: Compute SHA256("Hello World! This is Noir-ECDSA"[..31]) ===
                        let inputString = "Hello World! This is Noir-ECDSA"
                        let truncatedData = inputString.prefix(31).data(using: .utf8)!
                        let hash = SHA256.hash(data: truncatedData)
                        let hashBytes = Array(hash.prefix(32))  // [UInt8; 32]

                        // === Step 2: Define remaining inputs as hex strings ===
                        // Each 32-byte value is encoded as 64 hex characters
                        let rHex   = "6e6dd8df9cec8c31892d01e14318fb3109c73f335657be981f6387c44d3c8e0e"
                        let sHex   = "262ed99e46e6577a71a75b1d5c7f4acefc34f4b68aa019eda376372f2e762c2d"
                        let pkXHex = "d54378ffd74c0a0692ea56dc91e14aa683ef4c166c55cfb8d135863fc8f9aa1d"
                        let pkYHex = "6b6c3604db3440d3dc4ee95a24f0f0c4eae722e511eeb583122a0f6ab2554b36"
                        
                        let rBytes   = hexStringToBytes(rHex)
                        let sBytes   = hexStringToBytes(sHex)
                        let pkXBytes = hexStringToBytes(pkXHex)
                        let pkYBytes = hexStringToBytes(pkYHex)
                        
                        // === Step 3: Concatenate all values and convert to [String] ===
                        let allInputs: [String] = (hashBytes + rBytes + sBytes + pkXBytes + pkYBytes).map { String($0) }
                        print("📏 allInputs.count = \(allInputs.count)")
                        
                        // === Step 4: Call Noir proof generation ===
                        let proof = try generateNoirProof(circuitPath: circuitPath, srsPath: nil, inputs: allInputs)
                        
                        // === Step 5: Verify the Noir proof ===
                        let verifies = try verifyNoirProof(circuitPath: circuitPath, proof: proof)
                        
                        assert(verifies)

                        log = "✅ Noir proof generated and verified (\(proof.count) bytes)"
                    } catch {
                        log = "❌ Noir proof error: \(error.localizedDescription)"
                    }

                    stopTimer()
                    isRunningProof = false
                }
            }
            .disabled(isRunningProof)
            
            Button("Run App Attest") {
                Task {
                    await runAppAttestTest()
                }
            }
            .disabled(isRunningProof)

            Button("Run Assertion") {
                Task {
                    await runAssertionTest()
                }
            }
            .disabled(keyID == nil || isRunningProof)
        }
        .padding()
        .onAppear {
            Task {
            }
        }
    }
    

    func runAppAttestProof() {
        do {
            let output = try proveAttestation()
            print("✅ Output: \(output)")
            // Use `output` here as needed (e.g. update state/UI)
        } catch let error as Risc0Error {
            switch error {
            case .ProveError(let message):
                print("❌ Prove error: \(message)")
            case .SerializeError(let message):
                print("❌ Serialization error: \(message)")
            }
        } catch {
            print("❌ Unexpected error: \(error)")
        }
    }

    // MARK: - Proof helpers
    @MainActor
    func startProof() async {
        isRunningProof = true
        proofElapsed = 0
        startTimer()
        do {
            // Heavy work off the main thread
            let output = try await withCheckedThrowingContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        let result = try proveAttestation()
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            log = "✅ Output: \(output)"
        } catch let error as Risc0Error {
            switch error {
            case .ProveError(let message):
                log = "❌ Prove error: \(message)"
            case .SerializeError(let message):
                log = "❌ Serialization error: \(message)"
            }
        } catch {
            log = "❌ Unexpected error: \(error)"
        }
        stopTimer()
        isRunningProof = false
    }

    func startTimer() {
        proofTimer?.invalidate()
        proofTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            proofElapsed += 1
        }
    }

    func stopTimer() {
        proofTimer?.invalidate()
        proofTimer = nil
    }

    func runAppAttestTest() async {
        guard DCAppAttestService.shared.isSupported else {
            log = "❌ App Attest not supported."
            return
        }

        do {
            let challenge = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
            let challengeHash = SHA256.hash(data: challenge)

            let keyID = try await DCAppAttestService.shared.generateKey()
            let attestation = try await DCAppAttestService.shared.attestKey(keyID, clientDataHash: Data(challengeHash))

            self.keyID = keyID

            let payload: [String: String] = [
                "keyId": keyID,
                "attestation": attestation.base64EncodedString(),
                "challenge": challenge.base64EncodedString()
            ]

            let json = try JSONEncoder().encode(payload)
            let url = URL(string: "http://172.31.53.75:8888")!  // your Mac IP
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let _ = try await URLSession.shared.upload(for: req, from: json)

            log = "✅ Attestation done & sent.\nKeyID: \(keyID.prefix(8))…"

        } catch {
            log = "❌ Attestation error: \(error.localizedDescription)"
        }
    }

    func runAssertionTest() async {
        guard let keyID = keyID else {
            log = "❌ No attested keyID found."
            return
        }

        do {
            // 1. Generate a random claim like "x = 17"
            let x = Int.random(in: 0..<100)
            let claimString = "x = \(x)"
            let claim = Data(claimString.utf8)


            let claimHash = SHA256.hash(data: claim)
    

            // 3. Ask device to sign the challenge using the stored key
            let assertion = try await DCAppAttestService.shared.generateAssertion(
                keyID,
                clientDataHash: Data(claimHash)
            )

            // 4. Bundle payload
            let payload: [String: String] = [
                "keyID": keyID,
                "assertion": assertion.base64EncodedString(),
                "payload": claim.base64EncodedString(),
            ]

            // 5. Send to Mac
            let json = try JSONEncoder().encode(payload)
            let url = URL(string: "http://172.31.53.75:8888/assert")!
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let _ = try await URLSession.shared.upload(for: req, from: json)

            log = "✅ Sent assertion: \(claim)"

        } catch {
            log = "❌ Assertion error: \(error.localizedDescription)"
        }
    }
}

func hexStringToBytes(_ hex: String) -> [UInt8] {
    var bytes = [UInt8]()
    var index = hex.startIndex
    while index < hex.endIndex {
        let byteStr = hex[index..<hex.index(index, offsetBy: 2)]
        if let byte = UInt8(byteStr, radix: 16) {
            bytes.append(byte)
        }
        index = hex.index(index, offsetBy: 2)
    }
    return bytes
}
//
//#Preview {
//    ContentView()
//}
