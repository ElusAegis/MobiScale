import SwiftUI
import PhotosUI  // or AVFoundation if you prefer live capture

struct PhotoInferenceView: View {
    @State private var photoItem: PhotosPickerItem?
    @State private var isBusy = false
    var onComplete: (Data) -> Void   // ML output back to parent

    var body: some View {
        VStack(spacing: 16) {
            Text("📷 Take a photo")
                .font(.title2)

            PhotosPicker(selection: $photoItem,
                         matching: .images) {
                Label("Choose Photo", systemImage: "photo")
            }
            .disabled(isBusy)

            if isBusy { ProgressView("Running model…") }

            Spacer()
        }
        .onChange(of: photoItem) { _ in runModel() }
        .padding()
    }

    private func runModel() {
        guard let item = photoItem else { return }
        isBusy = true
        Task {
            let data = try? await item.loadTransferable(type: Data.self)
            // TODO: feed `data` into your CoreML/Metal model here…
            let dummyResult = Data("ml-output".utf8)   // placeholder
            await MainActor.run {
                isBusy = false
                onComplete(dummyResult)
            }
        }
    }
}
