import Foundation
import Combine

@MainActor
final class AssertionViewModel: ObservableObject {

    // Public state ----------------------------------------------------------
    @Published var step: Step = .idle
    @Published var progress: Double = 0            // 0…1 for ProgressView
    @Published var elapsed: TimeInterval = 0
    @Published var warning: String?                // shows banner on fallback

    enum Step: String {
        case idle        = "Waiting to start"
        case generating  = "Building composite proof (≈120 s)…"
        case finished    = "Done ✅"
        case failed      = "Failed ❌"
    }

    // Output back to parent -------------------------------------------------
    var onCompletion: ((AssertionResult, AssertionCompositeProof) -> Void)?
    
    init(flow: AppFlowViewModel) { self.flow = flow }

    // Private ---------------------------------------------------------------
    private let flow: AppFlowViewModel   // injected
    private var timer: Timer?
    private let expectedProveSeconds: TimeInterval = 120   // adjust if needed

    func run() {
        guard step == .idle else { return }
        step = .generating
        startTimer()

        Task.detached {
            await self.flow.runAssertion()
            await MainActor.run {
                self.stopTimer()
                self.step = .finished
            }
        }
    }

    // MARK: – Helpers
    private func startTimer() {
        progress = 0; elapsed = 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            elapsed += 1
            if step == .generating {
                progress = min(elapsed / expectedProveSeconds, 1)
            }
        }
    }
    private func stopTimer() { timer?.invalidate(); timer = nil }
}
