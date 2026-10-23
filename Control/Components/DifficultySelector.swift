import SwiftUI

/// 主观难度四选一，可以不选；再次点击已选项可取消选择。
struct DifficultySelector: View {
    @Binding var selection: Difficulty?

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: ControlSpacing.space2) {
                ForEach(Difficulty.allCases) { option($0) }
            }
            Grid(horizontalSpacing: ControlSpacing.space2, verticalSpacing: ControlSpacing.space2) {
                GridRow { option(.easy); option(.comfortable) }
                GridRow { option(.challenging); option(.tooHard) }
            }
        }
    }

    private func option(_ difficulty: Difficulty) -> some View {
        let isSelected = selection == difficulty
        let shape = RoundedRectangle(cornerRadius: ControlRadius.small + 2, style: .continuous)

        return Button {
            selection = isSelected ? nil : difficulty
        } label: {
            VStack(spacing: ControlSpacing.space1) {
                Image(systemName: difficulty.systemImage)
                    .font(.title3)
                    .foregroundStyle(isSelected ? ControlColors.brandDeep : ControlColors.inkSecondary)
                Text(difficulty.rawValue)
                    .font(ControlTypography.caption)
                    .foregroundStyle(ControlColors.inkPrimary)
                    .lineLimit(1)
                    .fixedSize()
            }
            .frame(maxWidth: .infinity, minHeight: 68)
            .padding(.horizontal, ControlSpacing.space1)
            .background(isSelected ? ControlColors.tealTint : ControlColors.surfaceLight.opacity(0.93), in: shape)
            .overlay(shape.strokeBorder(isSelected ? ControlColors.brandDeep : Color.white.opacity(0.7),
                                        lineWidth: isSelected ? 1.5 : 1))
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(difficulty.rawValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview("DifficultySelector") {
    @Previewable @State var selection: Difficulty? = .comfortable
    ZStack {
        ControlGradientBackground(theme: .complete)
        DifficultySelector(selection: $selection)
            .padding(ControlSpacing.screenHorizontal)
    }
}
