import SwiftUI

struct CelebrationOverlay: View {
    let dismiss: () -> Void

    var body: some View {
        ZStack {
            ConfettiCelebrationView()
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("🎉 You’re all caught up! No reminders pending.")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Text("Tap to continue")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            dismiss()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Celebration. You are all caught up with reminders. Tap to dismiss.")
    }
}

private struct ConfettiCelebrationView: View {
    @State private var startDate = Date()
    private let pieces: [ConfettiPiece] = ConfettiPiece.generate(count: 140)

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(startDate)
                for piece in pieces {
                    let state = piece.state(at: elapsed, canvasSize: size)
                    guard state.isVisible(in: size) else { continue }

                    var path = Path(
                        CGRect(
                            origin: .zero,
                            size: CGSize(width: state.size.width, height: state.size.height)
                        )
                    )
                    path = path
                        .applying(CGAffineTransform(translationX: -state.size.width / 2, y: -state.size.height / 2))
                        .applying(CGAffineTransform(rotationAngle: CGFloat(state.rotation)))
                        .applying(CGAffineTransform(translationX: state.position.x, y: state.position.y))

                    context.fill(path, with: .color(state.color))
                }
            }
        }
        .ignoresSafeArea()
    }
}

private struct ConfettiPiece: Hashable {
    let id: Int
    let hue: Double
    let saturation: Double
    let brightness: Double
    let baseX: Double
    let initialY: Double
    let verticalSpeed: Double
    let swayAmplitude: Double
    let swayFrequency: Double
    let phase: Double
    let rotationSpeed: Double
    let size: CGSize

    static func generate(count: Int) -> [ConfettiPiece] {
        (0..<count).map { index in
            let width = CGFloat.random(in: 8...16)
            let height = CGFloat.random(in: 12...24)
            return ConfettiPiece(
                id: index,
                hue: Double.random(in: 0...1),
                saturation: Double.random(in: 0.55...0.9),
                brightness: Double.random(in: 0.75...1.0),
                baseX: Double.random(in: 0...1),
                initialY: Double.random(in: -300 ... 0),
                verticalSpeed: Double.random(in: 90...170),
                swayAmplitude: Double.random(in: 20...60),
                swayFrequency: Double.random(in: 0.8...1.6),
                phase: Double.random(in: 0...(.pi * 2)),
                rotationSpeed: Double.random(in: -2.5...2.5),
                size: CGSize(width: width, height: height)
            )
        }
    }

    func state(at elapsed: TimeInterval, canvasSize: CGSize) -> ConfettiState {
        let width = canvasSize.width
        let height = canvasSize.height + 200 // extra buffer for offscreen start

        var y = initialY + verticalSpeed * elapsed
        y.formTruncatingRemainder(dividingBy: height)
        if y < -200 {
            y += height
        }

        let sway = swayAmplitude * sin((elapsed * swayFrequency) + phase)
        let x = baseX * width + sway

        let angle = rotationSpeed * elapsed

        return ConfettiState(
            position: CGPoint(x: CGFloat(x), y: CGFloat(y)),
            rotation: angle,
            color: Color(hue: hue, saturation: saturation, brightness: brightness),
            size: size
        )
    }
}

private struct ConfettiState {
    let position: CGPoint
    let rotation: Double
    let color: Color
    let size: CGSize

    func isVisible(in size: CGSize) -> Bool {
        position.y >= -200 && position.y <= size.height + 200
    }
}
