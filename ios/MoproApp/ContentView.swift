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
