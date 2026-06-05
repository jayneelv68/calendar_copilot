import SwiftUI

// First-launch welcome: a centered friendly card with a mini plane flying across.
struct WelcomeView: View {
    let personalization: Personalization
    let onDismiss: () -> Void

    @State private var planeProgress: CGFloat = 0
    @State private var cardOn: Bool = false

    var body: some View {
        ZStack {
            // Dim backdrop.
            LinearGradient(
                colors: [.black.opacity(0.25), .black.opacity(0.55)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Mini plane fly-by at top.
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let planeX = -150 + (w + 300) * planeProgress
                PlaneIcon(color: personalization.planeColor, size: 70)
                    .shadow(color: .black.opacity(0.22), radius: 6, x: 0, y: 4)
                    .position(x: planeX, y: h * 0.22)
                .onAppear {
                    withAnimation(.linear(duration: 4.5)) {
                        planeProgress = 1.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) {
                            cardOn = true
                        }
                    }
                }
            }

            // Welcome card.
            VStack(spacing: 18) {
                PlaneIcon(color: personalization.planeColor, size: 76)
                Text(personalization.welcomeMessage)
                    // New York serif: display weight for the headline.
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .tracking(-0.2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                Text(personalization.welcomeSubtitle)
                    // SF Pro at a generous line spacing for body copy.
                    .font(.system(size: 17, weight: .regular, design: .default))
                    .tracking(0.1)
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                Button(action: onDismiss) {
                    Text("Let's go")
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .tracking(0.4)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [personalization.bannerGradientStart, personalization.bannerGradientEnd],
                                startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }
            .padding(36)
            .frame(maxWidth: 520)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.25), radius: 30, x: 0, y: 16)
            .scaleEffect(cardOn ? 1.0 : 0.85)
            .opacity(cardOn ? 1 : 0)
        }
    }
}
