import UIKit

enum AvatarImageProcessingError: LocalizedError {
    case invalidImage
    case cannotReduceBelowLimit

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Ảnh đã chọn không hợp lệ. Vui lòng chọn ảnh khác."
        case .cannotReduceBelowLimit:
            return "Không thể giảm ảnh xuống dưới 2 MB. Vui lòng chọn ảnh khác."
        }
    }
}

enum AvatarImageProcessor {
    nonisolated static let maximumUploadBytes = 2 * 1_024 * 1_024

    nonisolated static func makeUploadJPEG(from sourceData: Data) throws -> Data {
        guard let sourceImage = UIImage(data: sourceData) else {
            throw AvatarImageProcessingError.invalidImage
        }

        for maximumDimension in [1_280.0, 1_024.0, 768.0] {
            let image = resizedImage(sourceImage, maximumDimension: maximumDimension)
            for quality in stride(from: 0.88, through: 0.38, by: -0.1) {
                if let data = image.jpegData(compressionQuality: quality),
                   data.count <= maximumUploadBytes {
                    return data
                }
            }
        }

        throw AvatarImageProcessingError.cannotReduceBelowLimit
    }

    nonisolated private static func resizedImage(_ image: UIImage, maximumDimension: CGFloat) -> UIImage {
        let longestSide = max(image.size.width, image.size.height)
        guard longestSide > maximumDimension else { return image }

        let scale = maximumDimension / longestSide
        let targetSize = CGSize(
            width: max(1, image.size.width * scale),
            height: max(1, image.size.height * scale)
        )
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
