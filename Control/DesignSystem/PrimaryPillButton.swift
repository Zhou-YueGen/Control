import SwiftUI

/// 主 CTA：绿色深浅渐变胶囊按钮。
/// 支持 正常 / 按下（缩放 0.98）/ 禁用（外部加 `.disabled(true)`）/ 加载中。
struct PrimaryPillButton: View {
    let title: String
    var systemImage: String? = nil
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: ControlSpacing.space2) {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(title)
                    if let systemImage {
                        Image(systemName: systemImage)
                    }
                }
            }
        }
        .buttonStyle(PrimaryPillButtonStyle())
        .allowsHitTesting(!isLoading)
        .accessibilityLabel(title)
        .accessibilityValue(isLoading ? "Loading" : "")
    }
}

private struct PrimaryPillButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ControlTypography.button)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: ControlSpacing.buttonMinHeight)
            .padding(.horizontal, ControlSpacing.space5)
            .background {
                if isEnabled {
                    Capsule().fill(
                        LinearGradient(colors: [ControlColors.brandMid, ControlColors.brandDeep],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                } else {
                    Capsule().fill(ControlColors.disabled)
                }
            }
            .shadow(color: ControlColors.brandDeep.opacity(isEnabled ? 0.25 : 0), radius: 12, y: 6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .contentShape(Capsule())
    }
}

#Preview("PrimaryPillButton") {
    ZStack {
        ControlGradientBackground(theme: .complete)
        VStack(spacing: ControlSpacing.space4) {
            PrimaryPillButton(title: "Save & Continue") {}
            PrimaryPillButton(title: "Continue") {}.disabled(true)
            PrimaryPillButton(title: "Saving", isLoading: true) {}
        }
        .padding(ControlSpacing.screenHorizontal)
    }
}
