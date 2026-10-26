import SwiftUI

/// 课程配图：示意图、节奏图或大图标。只做教育示意，不代表精确解剖结构。
struct LessonArt: View {
    let art: LearnLesson.Art

    var body: some View {
        switch art {
        case .pelvicDiagram: PelvicFloorDiagram()
        case .rhythm: RhythmIllustration()
        case .symbol(let name): SymbolArt(systemImage: name)
        }
    }
}

/// 男性骨盆侧面简化示意：膀胱、前列腺、尿道、直肠与托住它们的盆底肌。
struct PelvicFloorDiagram: View {
    private let bone = Color(hex: 0xF1D9C2)
    private let bladder = Color(hex: 0xDD6F84)
    private let prostate = Color(hex: 0xF0B49B)
    private let rectum = Color(hex: 0xD98A86)
    private let muscle = Color(hex: 0xC2475B)
    private let urethra = Color(hex: 0x8CC8DA)

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let p = { (x: CGFloat, y: CGFloat) in CGPoint(x: x * w, y: y * h) }

            ZStack {
                LinearGradient(colors: [Color(hex: 0xFCEDE3), Color(hex: 0xF8DCCB)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)

                // 尾骨与骶骨
                Path { path in
                    path.move(to: p(0.30, -0.05))
                    path.addQuadCurve(to: p(0.36, 0.92), control: p(0.14, 0.45))
                }
                .stroke(bone, style: StrokeStyle(lineWidth: 18, lineCap: .round))

                // 耻骨
                Capsule()
                    .fill(bone)
                    .frame(width: 0.07 * w, height: 0.26 * h)
                    .rotationEffect(.degrees(-20))
                    .position(p(0.76, 0.66))

                // 直肠
                Path { path in
                    path.move(to: p(0.36, 0.10))
                    path.addQuadCurve(to: p(0.42, 1.05), control: p(0.30, 0.60))
                }
                .stroke(rectum.opacity(0.75), style: StrokeStyle(lineWidth: 0.07 * w, lineCap: .round))

                // 尿道
                Path { path in
                    path.move(to: p(0.56, 0.58))
                    path.addQuadCurve(to: p(0.66, 1.05), control: p(0.58, 0.90))
                }
                .stroke(urethra, style: StrokeStyle(lineWidth: 3, lineCap: .round))

                // 膀胱
                Ellipse()
                    .fill(LinearGradient(colors: [bladder.opacity(0.85), bladder],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 0.30 * w, height: 0.44 * h)
                    .position(p(0.57, 0.36))

                // 前列腺
                Circle()
                    .fill(prostate)
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.6), lineWidth: 1))
                    .frame(width: 0.09 * w, height: 0.09 * w)
                    .position(p(0.57, 0.66))

                // 盆底肌：从耻骨到尾骨的“吊床”
                Path { path in
                    path.move(to: p(0.33, 0.80))
                    path.addQuadCurve(to: p(0.74, 0.76), control: p(0.52, 0.98))
                }
                .stroke(muscle, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                Path { path in
                    path.move(to: p(0.33, 0.80))
                    path.addQuadCurve(to: p(0.74, 0.76), control: p(0.52, 0.98))
                }
                .stroke(Color.white.opacity(0.35), style: StrokeStyle(lineWidth: 10, lineCap: .butt, dash: [1.5, 4]))

                label("Bladder", at: p(0.04, 0.34), alignment: .leading, lineTo: p(0.44, 0.34), from: p(0.18, 0.34))
                label("Prostate", at: p(0.97, 0.52), alignment: .trailing, lineTo: p(0.61, 0.64), from: p(0.82, 0.52))
                label("Pelvic floor muscles", at: p(0.04, 0.62), alignment: .leading,
                      lineTo: p(0.40, 0.86), from: p(0.30, 0.66))
            }
        }
        .clipped()
        .dynamicTypeSize(...DynamicTypeSize.large)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Simplified side-view illustration of the pelvis")
        .accessibilityValue("The pelvic floor muscles form a sling beneath the bladder, prostate and bowel.")
    }

    /// `point` 是标签靠左（`.leading`）或靠右（`.trailing`）的锚点，引线从 `start` 指向 `target`。
    private func label(_ text: String, at point: CGPoint, alignment: Alignment,
                       lineTo target: CGPoint, from start: CGPoint) -> some View {
        ZStack {
            Path { path in
                path.move(to: start)
                path.addLine(to: target)
            }
            .stroke(ControlColors.inkSecondary.opacity(0.7), lineWidth: 0.8)
            Circle()
                .fill(ControlColors.inkSecondary)
                .frame(width: 4, height: 4)
                .position(target)
            Text(text)
                .font(.caption2.weight(.medium))
                .foregroundStyle(ControlColors.inkPrimary)
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Color(hex: 0xFCEDE3).opacity(0.85), in: Capsule())
                .frame(width: 0, alignment: alignment)
                .position(point)
        }
    }
}

/// 收缩/放松节奏示意：短柱代表收缩，长段代表放松。
struct RhythmIllustration: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xD8F6EF), Color(hex: 0xBFE3EE)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(alignment: .leading, spacing: ControlSpacing.space3) {
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(LinearGradient(colors: [ControlColors.brandMint, ControlColors.brandMid],
                                                 startPoint: .top, endPoint: .bottom))
                            .frame(maxWidth: 26)
                            .frame(height: 72)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(ControlColors.sky.opacity(0.45))
                            .frame(maxWidth: 44)
                            .frame(height: 28)
                    }
                }
                .padding(.top, ControlSpacing.space8)
                HStack(spacing: ControlSpacing.space4) {
                    legend("Contract", color: ControlColors.brandMid)
                    legend("Relax", color: ControlColors.sky)
                }
            }
            .padding(ControlSpacing.space5)
        }
        .dynamicTypeSize(...DynamicTypeSize.large)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Illustration of alternating contract and relax phases")
    }

    private func legend(_ text: String, color: Color) -> some View {
        HStack(spacing: ControlSpacing.space1) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(ControlColors.inkSecondary)
        }
    }
}

/// 大图标配图，用于没有专门插图的课程。
struct SymbolArt: View {
    let systemImage: String

    var body: some View {
        ZStack {
            LinearGradient(colors: [ControlColors.tealTint, Color(hex: 0xE3EEF8)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle()
                .fill(Color.white.opacity(0.6))
                .frame(width: 120, height: 120)
            Image(systemName: systemImage)
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(LinearGradient(colors: [ControlColors.brandMid, ControlColors.brandDeep],
                                                startPoint: .top, endPoint: .bottom))
        }
        .accessibilityHidden(true)
    }
}

#Preview("Lesson art") {
    VStack(spacing: 16) {
        PelvicFloorDiagram().frame(height: 190)
        RhythmIllustration().frame(height: 190)
        SymbolArt(systemImage: "wind").frame(height: 190)
    }
    .padding()
}
