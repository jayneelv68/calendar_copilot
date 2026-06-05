import SwiftUI

// Plane icon — Apple's SF Symbol "airplane" (proper side-view jet), rotated so
// it flies horizontally to the right and tinted with the personalization color.
struct PlaneIcon: View {
    let color: Color
    let size: CGFloat
    var body: some View {
        Image(systemName: "airplane")
            .resizable()
            .scaledToFit()
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(color)
            // SF Symbol "airplane" points up-and-to-the-right by default;
            // rotating 45° clockwise makes the nose point straight right.
            .rotationEffect(.degrees(45))
            .frame(width: size, height: size)
    }
}

struct DottedContrailView: View {
    var color: Color
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<14, id: \.self) { i in
                Circle()
                    .fill(color.opacity(1.0 - Double(i) * 0.06))
                    .frame(width: CGFloat(6 - i/4), height: CGFloat(6 - i/4))
            }
        }
    }
}

struct SparkleParticle: Identifiable {
    let id = UUID()
    let dx: CGFloat
    let dy: CGFloat
    let delay: Double
    let symbol: String
}

struct PlaneFlightView: View {
    let bannerText: String
    let personalization: Personalization
    let onFinished: () -> Void

    @State private var phase: CGFloat = 0   // 0 → 1 across screen
    @State private var puff: Bool = false
    @State private var screenW: CGFloat = 1200

    private var particles: [SparkleParticle] {
        guard personalization.style == .warm else { return [] }
        return (0..<10).map { i in
            SparkleParticle(
                dx: CGFloat.random(in: -40...40),
                dy: CGFloat.random(in: -50...50),
                delay: Double(i) * 0.05,
                symbol: ["heart.fill", "sparkle", "sparkles"].randomElement() ?? "sparkle"
            )
        }
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let planeW: CGFloat = 120
            let planeH: CGFloat = 70
            let bannerW: CGFloat = max(360, CGFloat(bannerText.count) * 14 + 80)
            let bannerH: CGFloat = 70
            let y = h * 0.32
            // Plane travels from -200 → w+200 as phase 0 → 1.
            let totalDist = w + 400
            let planeX = -200 + totalDist * phase

            ZStack {
                // Banner trailing plane.
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [personalization.bannerGradientStart, personalization.bannerGradientEnd],
                                startPoint: .leading, endPoint: .trailing)
                        )
                        .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 5)
                    Text(bannerText)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundColor(personalization.bannerTextColor)
                        .lineLimit(1)
                        .padding(.horizontal, 24)
                }
                .frame(width: bannerW, height: bannerH)
                .position(x: planeX - bannerW/2 - 30, y: y + planeH/2)

                // Tow line.
                Path { p in
                    p.move(to: CGPoint(x: planeX - 30, y: y + planeH/2))
                    p.addLine(to: CGPoint(x: planeX - bannerW - 30, y: y + planeH/2))
                }
                .stroke(personalization.planeColor.opacity(0.6),
                        style: StrokeStyle(lineWidth: 2, dash: [4, 4]))

                // Dotted contrail behind plane.
                DottedContrailView(color: personalization.planeColor)
                    .position(x: planeX + planeW + 40, y: y + planeH/2)

                // Plane — Apple's SF Symbol airplane, tinted and flying right.
                PlaneIcon(color: personalization.planeColor, size: planeW)
                    .shadow(color: .black.opacity(0.22), radius: 6, x: 0, y: 4)
                    .position(x: planeX, y: y + planeH/2)

                // Sparkle puff near end.
                if puff {
                    ForEach(particles) { particle in
                        Image(systemName: particle.symbol)
                            .foregroundColor(personalization.planeColor)
                            .opacity(0.9)
                            .scaleEffect(puff ? 1.4 : 0.2)
                            .position(x: planeX + particle.dx, y: y + planeH/2 + particle.dy)
                            .animation(.easeOut(duration: 0.8).delay(particle.delay), value: puff)
                    }
                }
            }
            .onAppear {
                screenW = w
                withAnimation(.linear(duration: personalization.flightDurationSeconds)) {
                    phase = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + personalization.flightDurationSeconds * 0.75) {
                    puff = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + personalization.flightDurationSeconds + 0.4) {
                    onFinished()
                }
            }
        }
    }
}
