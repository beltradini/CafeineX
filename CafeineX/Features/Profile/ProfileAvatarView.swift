import SwiftUI
import UIKit

struct ProfileAvatarView: View {
    let data: Data?
    var size: CGFloat = 82

    var body: some View {
        Group {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [CXTheme.caffeineAccent, CXTheme.nicotineAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: size * 0.34, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            Circle()
                .stroke(.white.opacity(0.5), lineWidth: 2)
        }
        .accessibilityHidden(true)
    }
}
