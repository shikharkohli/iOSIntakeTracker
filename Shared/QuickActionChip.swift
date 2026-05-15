import SwiftUI

struct QuickActionChip: View {
    let label: String
    var glyph: String? = nil
    var wide: Bool = false
    var tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let glyph {
                    Image(systemName: glyph)
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(tint)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .frame(minWidth: 44, maxWidth: wide ? .infinity : nil, minHeight: 44)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: WatchTheme.Radius.chip))
            .overlay(
                RoundedRectangle(cornerRadius: WatchTheme.Radius.chip)
                    .stroke(tint.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        HStack { QuickActionChip(label: "½", tint: .cyan) {} ; QuickActionChip(label: "1", tint: .cyan) {} }
        QuickActionChip(label: "Bottle", wide: true, tint: .cyan) {}
    }
    .padding()
    .background(.black)
}
