import SwiftUI

struct PersonAvatarView: View {
    private let displayText: String
    private let palette: [Color]
    private let size: CGFloat
    private let font: Font

    init(
        person: Person,
        size: CGFloat = 40,
        font: Font = .title3
    ) {
        self.init(
            initials: person.firstInitial,
            seed: person.id.uuidString,
            size: size,
            font: font
        )
    }

    init(
        initials: String,
        seed: String,
        size: CGFloat = 40,
        font: Font = .title3
    ) {
        self.displayText = initials
        self.palette = Self.palette(for: seed)
        self.size = size
        self.font = font
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: palette,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .overlay {
                    Circle()
                        .fill(.white.opacity(0.18))
                        .blendMode(.plusLighter)
                }
                .overlay {
                    Circle()
                        .strokeBorder(.white.opacity(0.25), lineWidth: 1)
                        .blendMode(.overlay)
                }

            Text(displayText)
                .font(font)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.82))
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.12), radius: size / 12, x: 0, y: size / 18)
        .accessibilityHidden(true)
    }
}

private extension PersonAvatarView {
    static let gradientPalettes: [[Color]] = [
        [.indigo, .cyan],
        [.purple, .pink],
        [.blue, .teal],
        [.orange, .yellow],
        [.mint, .green],
        [.red, .orange]
    ]

    static func palette(for seed: String) -> [Color] {
        let index = abs(stableHash(for: seed)) % gradientPalettes.count
        return gradientPalettes[index]
    }

    static func stableHash(for value: String) -> Int {
        value.unicodeScalars.reduce(0) { accumulator, scalar in
            let scalarValue = Int(scalar.value)
            return (accumulator &* 31 &+ scalarValue) & 0x7fffffff
        }
    }
}
