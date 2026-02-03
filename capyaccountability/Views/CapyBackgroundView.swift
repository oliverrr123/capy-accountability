import SwiftUI

struct CapyBackgroundView: View {
    var imageName: String = "capy_wallpaper"

    var body: some View {
        ZStack {
            Color.capyBlue
                .ignoresSafeArea()

            Image(imageName)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .opacity(0.9)

            LinearGradient(
                colors: [
                    Color.black.opacity(0.25),
                    Color.black.opacity(0.15),
                    Color.black.opacity(0.05),
                    Color.black.opacity(0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}

#Preview {
    CapyBackgroundView()
}
