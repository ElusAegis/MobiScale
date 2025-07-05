import Foundation

@MainActor
final class RandomnessViewModel: ObservableObject {
    enum Step: String { case idle, fetching, done, failed }

    @Published var step: Step = .idle
    @Published var challenge: RandomnessChallenge?
    @Published var error: String?

    private let provider: RandomnessProvider
    init(provider: RandomnessProvider = DrandRandomnessService()) {
        self.provider = provider
    }

    func fetch() {
        guard step == .idle else { return }
        step = .fetching
        Task {
            do {
                let c = try await provider.fetchChallenge()
                await MainActor.run {
                    challenge = c
                    step = .done
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.step  = .failed
                }
            }
        }
    }
}
