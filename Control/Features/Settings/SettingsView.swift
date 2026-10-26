import SwiftUI

/// S11 Settings（P0）：声音与振动、安全信息、隐私说明、删除全部本地数据。
/// 提醒、导出、声音选择属于 P1，未实现前不放置无效开关。
struct SettingsView: View {
    let router: AppRouter

    @State private var isConfirmingDelete = false

    var body: some View {
        @Bindable var preferences = router.preferences

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: ControlSpacing.space5) {
                    Text("Settings")
                        .font(ControlTypography.screenTitle)
                        .foregroundStyle(ControlColors.inkOnDark)
                        .accessibilityAddTraits(.isHeader)

                    section("Training") {
                        Toggle(isOn: $preferences.soundEnabled) {
                            rowLabel("Sound Guidance", systemImage: "speaker.wave.2.fill",
                                     detail: "Spoken countdown during sessions")
                        }
                        .accessibilityIdentifier("soundToggle")
                        divider
                        Toggle(isOn: $preferences.hapticsEnabled) {
                            rowLabel("Haptic Feedback", systemImage: "iphone.radiowaves.left.and.right",
                                     detail: "A gentle tap when the phase changes")
                        }
                        .accessibilityIdentifier("hapticsToggle")
                    }

                    section("Safety") {
                        NavigationLink {
                            SafetyInformationView(preferences: router.preferences)
                        } label: {
                            HStack {
                                rowLabel("Safety Information", systemImage: "cross.case.fill",
                                         detail: "When to stop and seek support")
                                Spacer(minLength: 0)
                                chevron
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("safetyInformationRow")
                    }

                    section("Privacy") {
                        rowLabel("Your data stays on this device", systemImage: "lock.fill",
                                 detail: "No account, no cloud sync and no analytics.")
                        divider
                        rowLabel("Privacy Policy", systemImage: "doc.text",
                                 detail: "Available before public release")
                            .opacity(0.6)
                            .accessibilityHint("Not available yet")
                    }

                    section("Data") {
                        Button(role: .destructive) {
                            isConfirmingDelete = true
                        } label: {
                            HStack {
                                rowLabel("Delete All Data", systemImage: "trash.fill",
                                         detail: "Erase sessions, feedback and setup", tint: ControlColors.danger)
                                Spacer(minLength: 0)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("deleteAllDataButton")
                    }

                    if router.store.lastSaveFailed {
                        Label("Your latest changes couldn't be saved on this device.", systemImage: "exclamationmark.triangle.fill")
                            .font(ControlTypography.caption)
                            .foregroundStyle(ControlColors.danger)
                    }
                }
                .padding(.horizontal, ControlSpacing.screenHorizontal)
                .padding(.top, ControlSpacing.space2)
                .padding(.bottom, ControlSpacing.space6)
            }
            .fadesUnderStatusBar()
            .background(ControlGradientBackground(theme: .settings))
            .toolbar(.hidden, for: .navigationBar)
        }
        .tint(ControlColors.brandDeep)
        .alert("Delete all data?", isPresented: $isConfirmingDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                router.deleteAllData()
            }
        } message: {
            Text("This permanently removes your training history, feedback, setup answers, safety status and settings from this device, and returns you to the welcome screen. Copies in existing device backups may not be removed immediately.")
        }
    }

    // MARK: - Building blocks

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: ControlSpacing.space2) {
            Text(title.uppercased())
                .font(ControlTypography.caption.weight(.semibold))
                .foregroundStyle(ControlColors.inkOnDarkMuted)
                .padding(.leading, ControlSpacing.space2)
                .accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: ControlSpacing.space3) {
                content()
            }
            .padding(ControlSpacing.space4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ControlColors.surfaceLight,
                        in: RoundedRectangle(cornerRadius: ControlRadius.card, style: .continuous))
        }
    }

    private func rowLabel(_ title: String, systemImage: String, detail: String,
                          tint: Color = ControlColors.brandDeep) -> some View {
        HStack(spacing: ControlSpacing.space3) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(ControlTypography.body.weight(.medium))
                    .foregroundStyle(tint == ControlColors.danger ? tint : ControlColors.inkPrimary)
                Text(detail)
                    .font(ControlTypography.caption)
                    .foregroundStyle(ControlColors.inkSecondary)
            }
        }
        .frame(minHeight: ControlSpacing.hitTargetMin)
    }

    private var divider: some View {
        Divider().overlay(ControlColors.separatorLight)
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(ControlColors.inkSecondary)
            .accessibilityHidden(true)
    }
}

#Preview("Settings") {
    SettingsView(router: .previewOnboarded())
}
