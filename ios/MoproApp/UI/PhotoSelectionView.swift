import SwiftUI
import PhotosUI

struct PhotoSelectionView: View {
    @StateObject private var vm = IdentityMatchViewModel()
    @State private var passportItem: PhotosPickerItem?
    @State private var selfieData: Data?
    @State private var showingCamera = false
    let onComplete: (IdentityMatchOutput) -> Void
    
    // Computed properties to break down complex conditions
    private var isPassportProcessing: Bool {
        vm.isProcessing && vm.step == .selectPassport
    }
    
    private var isSelfieProcessing: Bool {
        vm.isProcessing && vm.step == .captureSelfie
    }
    
    private var bothPhotosReady: Bool {
        vm.passportValidated && vm.selfieValidated && vm.step != .comparing
    }
    
    private var canStartVerification: Bool {
        vm.passportValidated && vm.selfieValidated && vm.step != .comparing && vm.step != .success
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("📸 Photo Verification")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Upload your passport and take a selfie for identity verification")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Photo Selection Cards
            VStack(spacing: 16) {
                // Passport Photo Card
                PassportPhotoCard(
                    title: "Passport Photo",
                    subtitle: "Upload a clear photo of your passport or ID",
                    icon: "doc.text",
                    isCompleted: vm.passportValidated,
                    isProcessing: isPassportProcessing,
                    passportItem: $passportItem,
                    onRetry: {
                        vm.resetPassportOnly()
                        passportItem = nil
                    }
                )
                
                // Selfie Photo Card
                SelfiePhotoCard(
                    title: "Selfie Photo",
                    subtitle: "Take a clear photo of yourself",
                    icon: "person.crop.circle",
                    isCompleted: vm.selfieValidated,
                    isProcessing: isSelfieProcessing,
                    showingCamera: $showingCamera,
                    onRetry: {
                        vm.resetSelfieOnly()
                        selfieData = nil
                    }
                )
            }
            
            // Progress indicator
            if bothPhotosReady {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Both photos ready!")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
  
            
            Spacer()
            
            // Error display
            if let error = vm.error {
                ErrorDisplayView(error: error)
            }
            
            // Start Verification Button (fixed at bottom)
            if canStartVerification {
                VStack(spacing: 8) {
                    Button("Start Verification") {
                        vm.compareFaces(onComplete: onComplete)
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    
                    // Debug reset button
                    Button("Reset All Photos") {
                        vm.resetForRetry()
                        passportItem = nil
                        selfieData = nil
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .padding()
        .onChange(of: passportItem) { _, newValue in
            handlePassportSelection(newValue)
        }
        .onChange(of: selfieData) { _, newValue in
            if let newValue = newValue {
                vm.error = nil
                vm.processImage(newValue, for: .selfie)
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(imageData: $selfieData)
        }
    }
    
    private func handlePassportSelection(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        vm.error = nil
        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self) {
                    vm.processImage(data, for: .passport)
                } else {
                    await MainActor.run {
                        vm.error = "Failed to load passport photo. Please try again."
                        vm.isProcessing = false
                    }
                }
            } catch {
                await MainActor.run {
                    vm.error = "Failed to load passport photo: \(error.localizedDescription)"
                    vm.isProcessing = false
                }
            }
        }
    }
}

struct PassportPhotoCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let isCompleted: Bool
    let isProcessing: Bool
    @Binding var passportItem: PhotosPickerItem?
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: icon)
                            .foregroundColor(.blue)
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isCompleted {
                    Button("Change") {
                        onRetry()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            if isProcessing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Processing...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else if isCompleted {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Photo validated successfully")
                        .font(.caption)
                        .foregroundColor(.green)
                    Spacer()
                }
            } else {
                PhotosPicker(selection: $passportItem, matching: .images) {
                    HStack {
                        Image(systemName: "photo.badge.plus")
                        Text("Select Photo")
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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

struct SelfiePhotoCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let isCompleted: Bool
    let isProcessing: Bool
    @Binding var showingCamera: Bool
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: icon)
                            .foregroundColor(.blue)
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isCompleted {
                    Button("Change") {
                        onRetry()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            if isProcessing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Processing...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else if isCompleted {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Photo validated successfully")
                        .font(.caption)
                        .foregroundColor(.green)
                    Spacer()
                }
            } else {
                Button {
                    showingCamera = true
                } label: {
                    HStack {
                        Image(systemName: "camera")
                        Text("Take Selfie")
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.green)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Error Display View
struct ErrorDisplayView: View {
    let error: String
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with icon and title
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                    .symbolEffect(.bounce, options: .repeating, value: isVisible)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Verification Failed")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    
                    Text("Please review and try again")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Main error message
            Text(error)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 4)
            
            // Additional guidance for specific errors
            if error.contains("could not quite match") {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        
                        Text("Tips for better results:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                        
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        TipRow(icon: "camera.fill", text: "Ensure good lighting")
                        TipRow(icon: "eye.fill", text: "Look directly at the camera")
                        TipRow(icon: "person.crop.circle", text: "Remove glasses if possible")
                        TipRow(icon: "photo.fill", text: "Use a clear, recent passport photo")
                    }
                    .padding(.leading, 20)
                }
                .padding(.top, 4)
            } else if error.contains("No face detected") {
                HStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                        .foregroundColor(.orange)
                        .font(.caption)
                    
                    Text("Make sure your face is clearly visible and centered in the photo")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            } else if error.contains("timeout") {
                HStack(spacing: 8) {
                    Image(systemName: "clock.badge.exclamationmark")
                        .foregroundColor(.orange)
                        .font(.caption)
                    
                    Text("Processing took too long. Please check your connection and try again")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.red.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                )
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Tip Row Component
struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 12)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}
