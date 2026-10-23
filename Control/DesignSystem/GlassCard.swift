import SwiftUI

/// 统一圆角、底色、描边和阴影的卡片（DESIGN.md 2.5）。
/// `.light` 用于正文和需要阅读的内容；`.dark` 用于深色页面上的轻玻璃面板。
struct GlassCard<Content: View>: View {
    enum Style {
        case light
        case tinted
        case dark
    }

    var style: Style = .light
    var padding: CGFloat = ControlSpacing.space4
    var cornerRadius: CGFloat = ControlRadius.card
    @ViewBuilder var content: Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .background {
                switch style {
                case .light:
                    shape.fill(ControlColors.surfaceLight.opacity(0.93))
                case .tinted:
                    shape.fill(ControlColors.tealTint.opacity(0.85))
                case .dark:
                    shape.fill(.thinMaterial)
                        .overlay(shape.fill(ControlColors.surfaceDark.opacity(0.6)))
                }
            }
            .overlay {
                shape.strokeBorder(
                    style == .dark ? Color.white.opacity(0.14) : Color.white.opacity(0.7),
                    lineWidth: 1
                )
            }
            .clipShape(shape)
            .shadow(color: .black.opacity(style == .dark ? 0.12 : 0.06), radius: 16, y: 6)
    }
}

#Preview("GlassCard") {
    ZStack {
        ControlGradientBackground(theme: .home)
        VStack(spacing: ControlSpacing.space4) {
            GlassCard {
                Text("Light card").font(ControlTypography.cardTitle).foregroundStyle(ControlColors.inkPrimary)
            }
            GlassCard(style: .tinted) {
                Text("Tinted card").font(ControlTypography.cardTitle).foregroundStyle(ControlColors.inkPrimary)
            }
            GlassCard(style: .dark) {
                Text("Dark glass").font(ControlTypography.cardTitle).foregroundStyle(ControlColors.inkOnDark)
            }
        }
        .padding(ControlSpacing.screenHorizontal)
    }
}
