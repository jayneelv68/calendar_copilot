import SwiftUI

// Side-view jet drawn from scratch so the orientation is guaranteed horizontal,
// nose pointing right. Built as a union of four simple subpaths (fuselage,
// nose cone, tail fin, swept wing) — non-zero fill rule unions them cleanly.
struct PlaneShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height

        // Fuselage: horizontal rounded capsule.
        let fy = h * 0.40, fh = h * 0.20
        p.addPath(Path(roundedRect: CGRect(x: w * 0.04, y: fy,
                                           width: w * 0.84, height: fh),
                       cornerSize: CGSize(width: fh / 2, height: fh / 2)))

        // Pointed nose cone on the right.
        var nose = Path()
        nose.move(to: CGPoint(x: w * 0.78, y: fy - h * 0.02))
        nose.addLine(to: CGPoint(x: w * 1.00, y: fy + fh / 2))
        nose.addLine(to: CGPoint(x: w * 0.78, y: fy + fh + h * 0.02))
        nose.closeSubpath()
        p.addPath(nose)

        // Vertical stabilizer (tail fin) on the upper-left, swept back.
        var fin = Path()
        fin.move(to: CGPoint(x: w * 0.06, y: fy + h * 0.02))
        fin.addLine(to: CGPoint(x: w * 0.16, y: h * 0.06))
        fin.addLine(to: CGPoint(x: w * 0.32, y: h * 0.06))
        fin.addLine(to: CGPoint(x: w * 0.34, y: fy + h * 0.02))
        fin.closeSubpath()
        p.addPath(fin)

        // Main wing extending down, swept back.
        var wing = Path()
        wing.move(to: CGPoint(x: w * 0.34, y: fy + fh - h * 0.02))
        wing.addLine(to: CGPoint(x: w * 0.22, y: h * 0.94))
        wing.addLine(to: CGPoint(x: w * 0.54, y: h * 0.94))
        wing.addLine(to: CGPoint(x: w * 0.62, y: fy + fh - h * 0.02))
        wing.closeSubpath()
        p.addPath(wing)

        return p
    }
}

struct PlaneIcon: View {
    let color: Color
    let size: CGFloat
    var body: some View {
        PlaneShape()
            .fill(color)
            .frame(width: size, height: size * 0.62)
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
            let bannerW: CGFloat = max(420, CGFloat(bannerText.count) * 18 + 88)
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
                        // New York (Apple's display serif) — refined, designer-grade.
                        .font(.system(size: 30, weight: .semibold, design: .serif))
                        .tracking(0.3)
                        .foregroundColor(personalization.bannerTextColor)
                        .lineLimit(1)
                        .padding(.horizontal, 28)
                }
                .frame(width: bannerW, height: bannerH)
                .position(x: planeX - bannerW/2 - 28, y: y + planeH/2)

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
