import AVFoundation
import Photos
import SwiftUI
import UIKit

enum AvatarPickerSource: String, Identifiable {
    case camera
    case photoLibrary

    var id: String { rawValue }

    var sourceType: UIImagePickerController.SourceType {
        switch self {
        case .camera: return .camera
        case .photoLibrary: return .photoLibrary
        }
    }
}

enum AvatarMediaPermission {
    static func request(for source: AvatarPickerSource) async -> Bool {
        switch source {
        case .camera:
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                return true
            case .notDetermined:
                return await AVCaptureDevice.requestAccess(for: .video)
            case .denied, .restricted:
                return false
            @unknown default:
                return false
            }

        case .photoLibrary:
            let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            let status = currentStatus == .notDetermined
                ? await PHPhotoLibrary.requestAuthorization(for: .readWrite)
                : currentStatus
            return status == .authorized || status == .limited
        }
    }
}

struct AvatarImagePicker: UIViewControllerRepresentable {
    let source: AvatarPickerSource
    let onCompletion: (Result<Data, Error>?) -> Void

    static func isAvailable(_ source: AvatarPickerSource) -> Bool {
        UIImagePickerController.isSourceTypeAvailable(source.sourceType)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onCompletion: onCompletion)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = source.sourceType
        picker.allowsEditing = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let onCompletion: (Result<Data, Error>?) -> Void

        init(onCompletion: @escaping (Result<Data, Error>?) -> Void) {
            self.onCompletion = onCompletion
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCompletion(nil)
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
            guard let image, let data = image.jpegData(compressionQuality: 1) else {
                onCompletion(.failure(AvatarImageProcessingError.invalidImage))
                return
            }
            onCompletion(.success(data))
        }
    }
}
