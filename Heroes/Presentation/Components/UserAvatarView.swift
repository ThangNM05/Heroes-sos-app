import SwiftUI

struct UserAvatarView: View {
    let urlString: String?
    let initials: String
    let size: CGFloat

    var body: some View {
        Group {
            if let urlString,
               let url = URL(string: urlString),
               url.scheme?.lowercased() == "https" {
                AsyncImage(url: url, transaction: Transaction(animation: .easeInOut(duration: 0.2))) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .empty:
                        ZStack {
                            fallback
                            ProgressView().tint(.white)
                        }
                    case .failure:
                        fallback
                    @unknown default:
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityLabel("Ảnh đại diện của \(initials)")
    }

    private var fallback: some View {
        ZStack {
            Circle().fill(Theme.Colors.primaryColor)
            Text(initials.isEmpty ? "HR" : initials)
                .font(Theme.Fonts.bold.swiftUI(size: max(11, size * 0.32)))
                .foregroundColor(.white)
        }
    }
}
