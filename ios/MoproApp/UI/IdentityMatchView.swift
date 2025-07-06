import SwiftUI
import PhotosUI
import AVFoundation

struct IdentityMatchView: View {
    @StateObject private var vm = IdentityMatchViewModel()
    @State private var passportItem: PhotosPickerItem?
    @State private var selfieData: Data?
    @State private var showingCamera = false
    var onComplete: (Data) -> Void

    var body: some View {
        VStack(spacing: 16) {
            switch vm.step {
            case .selectPassport:
                VStack(spacing: 16) {
                    Text("🛂 Select a passport photo")
                        .font(.headline)
                    
                    Text("Choose a clear photo of your passport or ID document")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    PhotosPicker(selection: $passportItem, matching: .images) {
                        Label("Choose Passport Photo", systemImage: "photo")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .onChange(of: passportItem) { _, newValue in
                    if newValue != nil {
                        vm.error = nil // Clear any previous errors
                        vm.step = .captureSelfie
                    }
                }

            case .captureSelfie:
                VStack(spacing: 16) {
                    Text("📷 Take a selfie with front camera")
                        .font(.headline)
                    
                    Text("Take a clear photo of yourself in good lighting")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button {
                        showingCamera = true
                    } label: {
                        Label("Take Selfie", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .onChange(of: selfieData) { _, newValue in
                    if newValue != nil {
                        Task {
                            let passportData = try? await passportItem?.loadTransferable(type: Data.self)
                            
                            vm.processImages(passportData: passportData,
                                                   selfieData:   selfieData,
                                                   onComplete:   onComplete)
                        }
                    }
                }

            case .comparing:
                ProgressView("Running model…")
            case .done:
                VStack(spacing: 8) {
                    Text("✅ Photos processed")
                    Button("Continue") { /* nothing – flow advances automatically */ }
                        .hidden()
                }
            }

            if let error = vm.error {
                VStack(spacing: 8) {
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    
                    if vm.step == .selectPassport {
                        VStack(spacing: 12) {
                            Text("Please select a new passport photo and take a fresh selfie.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button("Try Again") {
                                vm.resetForRetry()
                                passportItem = nil
                                selfieData = nil
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingCamera) {
            CameraView(imageData: $selfieData)
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraDevice = .front
        picker.cameraCaptureMode = .photo
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage,
               let data = image.jpegData(compressionQuality: 0.8) {
                parent.imageData = data
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
