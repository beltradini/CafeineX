import SwiftUI

enum CafeineXOnboarding {
    static let completionKey = "cafeinex.onboarding.completed"
}

struct OnboardingView: View {
    @Environment(SleepScheduleStore.self) private var sleepScheduleStore
    @Environment(CaffeineSensitivityStore.self) private var sensitivityStore

    let onComplete: () -> Void

    @State private var step = 0
    @State private var bedtime: Date = .now
    @State private var sensitivity: CaffeineSensitivityProfile = .typical

    private let pageCount = 5

    var body: some View {
        ZStack {
            CXBackgroundView()

            VStack(spacing: 0) {
                topBar

                ZStack {
                    page
                        .id(step)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                bottomBar
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 18)
        }
        .task {
            bedtime = sleepScheduleStore.bedtimeDate()
            sensitivity = sensitivityStore.profile
        }
        .sensoryFeedback(.selection, trigger: step)
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "cup.and.saucer.fill")
                    .foregroundStyle(CXTheme.caffeineAccent)
                Text("CafeineX")
                    .font(.headline.weight(.bold))
            }

            Spacer()

            if step < pageCount - 1 {
                Button("Skip") {
                    complete()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            }
        }
        .frame(height: 32)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("CafeineX welcome")
    }

    @ViewBuilder
    private var page: some View {
        switch step {
        case 0:
            welcomePage
        case 1:
            awarenessPage
        case 2:
            privacyPage
        case 3:
            personalizePage
        default:
            readyPage
        }
    }

    private var welcomePage: some View {
        OnboardingPage(
            illustration: .welcome,
            eyebrow: "A clearer view of your routine",
            title: "Understand the timing of your stimulants",
            message: "CafeineX helps you record caffeine and nicotine, then place those moments beside your recorded sleep.",
            buttonTitle: "Continue",
            action: advance
        )
    }

    private var awarenessPage: some View {
        OnboardingPage(
            illustration: .awareness,
            eyebrow: "Simple, useful, personal",
            title: "Notice patterns without judgment",
            message: "Log what matters in seconds, explore your timeline, and build awareness around the moments that shape your day.",
            features: [
                .init(title: "Quick logging", symbol: "plus.circle.fill", tint: CXTheme.caffeineAccent),
                .init(title: "Complete history", symbol: "clock.arrow.circlepath", tint: CXTheme.healthAccent),
                .init(title: "Personal guidance", symbol: "moon.stars.fill", tint: CXTheme.nicotineAccent),
            ],
            buttonTitle: "Continue",
            action: advance
        )
    }

    private var privacyPage: some View {
        OnboardingPage(
            illustration: .health,
            eyebrow: "Optional Apple Health connection",
            title: "Your health data stays in your hands",
            message: "CafeineX can optionally read recent sleep and sync dietary caffeine. You can use every local tracking feature without connecting Apple Health.",
            features: [
                .init(title: "Caffeine", detail: "Optional read and write", symbol: "cup.and.saucer.fill", tint: CXTheme.caffeineAccent),
                .init(title: "Sleep", detail: "Optional read-only access", symbol: "moon.stars.fill", tint: CXTheme.healthAccent),
                .init(title: "Other health data", detail: "Not requested", symbol: "lock.shield.fill", tint: .secondary),
            ],
            footnote: "CafeineX does not diagnose, rate sleep quality, or claim that one event caused another.",
            buttonTitle: "Continue",
            action: advance
        )
    }

    private var personalizePage: some View {
        VStack(spacing: 22) {
            OnboardingIllustration(kind: .personalize)

            VStack(spacing: 8) {
                Text("MAKE IT YOURS")
                    .font(.caption.weight(.bold))
                    .tracking(1.4)
                    .foregroundStyle(CXTheme.caffeineAccent)

                Text("Set your personal context")
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .multilineTextAlignment(.center)

                Text("These preferences shape your guidance. You can change them anytime in Profile.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            CXSurfaceCard(contentPadding: EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)) {
                VStack(spacing: 14) {
                    DatePicker(
                        "Usual bedtime",
                        selection: $bedtime,
                        displayedComponents: .hourAndMinute
                    )

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Caffeine response")
                            .font(.subheadline.weight(.semibold))
                        Picker("Caffeine response", selection: $sensitivity) {
                            ForEach(CaffeineSensitivityProfile.allCases) { profile in
                                Text(profile.title).tag(profile)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                }
            }

            Spacer(minLength: 0)

            primaryButton("Continue", action: advance)
        }
        .padding(.top, 20)
    }

    private var readyPage: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 0)

            OnboardingIllustration(kind: .ready)

            VStack(spacing: 9) {
                Text("READY WHEN YOU ARE")
                    .font(.caption.weight(.bold))
                    .tracking(1.4)
                    .foregroundStyle(CXTheme.healthAccent)

                Text("Your next moment starts here")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .multilineTextAlignment(.center)

                Text("Start with a quick local entry. Connect Apple Health later whenever it feels right.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            primaryButton("Start using CafeineX", action: complete)
        }
        .padding(.top, 20)
    }

    private var bottomBar: some View {
        VStack(spacing: 14) {
            if step < pageCount - 2 {
                progressIndicator
            }

            if step == pageCount - 2 {
                progressIndicator
            }
        }
        .padding(.top, 12)
    }

    private var progressIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<pageCount, id: \.self) { index in
                Capsule()
                    .fill(index <= step ? CXTheme.healthAccent : Color.primary.opacity(0.12))
                    .frame(height: 5)
                    .animation(.easeInOut(duration: 0.25), value: step)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Onboarding step \(step + 1) of \(pageCount)")
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
        }
        .buttonStyle(.borderedProminent)
        .tint(CXTheme.healthAccent)
        .accessibilityIdentifier("onboarding-primary-action")
    }

    private func advance() {
        guard step < pageCount - 1 else {
            complete()
            return
        }
        withAnimation(.easeInOut(duration: 0.35)) {
            step += 1
        }
    }

    private func complete() {
        sleepScheduleStore.setBedtime(bedtime)
        sensitivityStore.setProfile(sensitivity)
        onComplete()
    }
}

private struct OnboardingPage: View {
    let illustration: OnboardingIllustration.Kind
    let eyebrow: String
    let title: String
    let message: String
    var features: [Feature] = []
    var footnote: String?
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 0)

            OnboardingIllustration(kind: illustration)

            VStack(spacing: 9) {
                Text(eyebrow.uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(1.4)
                    .foregroundStyle(CXTheme.caffeineAccent)

                Text(title)
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !features.isEmpty {
                VStack(spacing: 9) {
                    ForEach(features) { feature in
                        featureRow(feature)
                    }
                }
            }

            if let footnote {
                Text(footnote)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
            primaryButton
        }
        .padding(.top, 18)
    }

    private func featureRow(_ feature: Feature) -> some View {
        HStack(spacing: 12) {
            Image(systemName: feature.symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(feature.tint)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(.subheadline.weight(.semibold))
                if let detail = feature.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }

    private var primaryButton: some View {
        Button(action: action) {
            Text(buttonTitle)
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
        }
        .buttonStyle(.borderedProminent)
        .tint(CXTheme.healthAccent)
        .accessibilityIdentifier("onboarding-primary-action")
    }

    struct Feature: Identifiable {
        let id = UUID()
        let title: String
        let detail: String?
        let symbol: String
        let tint: Color

        init(
            title: String,
            detail: String? = nil,
            symbol: String,
            tint: Color
        ) {
            self.title = title
            self.detail = detail
            self.symbol = symbol
            self.tint = tint
        }
    }
}

private struct OnboardingIllustration: View {
    enum Kind {
        case welcome
        case awareness
        case health
        case personalize
        case ready
    }

    let kind: Kind
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Circle()
                .fill(primaryTint.opacity(0.12))
                .frame(width: 208, height: 208)
                .scaleEffect(isAnimating ? 1.04 : 0.96)

            Circle()
                .stroke(primaryTint.opacity(0.18), lineWidth: 1)
                .frame(width: 172, height: 172)

            illustration
        }
        .frame(height: 220)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }

    @ViewBuilder
    private var illustration: some View {
        switch kind {
        case .welcome:
            HStack(spacing: -5) {
                icon("cup.and.saucer.fill", tint: CXTheme.caffeineAccent, size: 64)
                icon("moon.stars.fill", tint: CXTheme.healthAccent, size: 72)
            }
        case .awareness:
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: 148, height: 94)
                HStack(alignment: .bottom, spacing: 8) {
                    bar(height: 24, tint: CXTheme.caffeineAccent)
                    bar(height: 48, tint: CXTheme.nicotineAccent)
                    bar(height: 70, tint: CXTheme.healthAccent)
                    bar(height: 38, tint: CXTheme.caffeineAccent)
                }
            }
        case .health:
            ZStack {
                icon("heart.fill", tint: CXTheme.healthAccent, size: 72)
                Image(systemName: "lock.fill")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(.white)
                    .offset(y: 4)
            }
        case .personalize:
            HStack(spacing: 13) {
                icon("moon.zzz.fill", tint: CXTheme.healthAccent, size: 58)
                icon("slider.horizontal.3", tint: CXTheme.caffeineAccent, size: 52)
            }
        case .ready:
            ZStack {
                icon("sparkles", tint: CXTheme.healthAccent, size: 70)
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(CXTheme.caffeineAccent)
                    .offset(x: 32, y: 30)
            }
        }
    }

    private var primaryTint: Color {
        switch kind {
        case .welcome, .awareness: CXTheme.caffeineAccent
        case .health, .ready: CXTheme.healthAccent
        case .personalize: CXTheme.nicotineAccent
        }
    }

    private var accessibilityLabel: String {
        switch kind {
        case .welcome: "Caffeine and sleep symbols"
        case .awareness: "A simple personal timeline"
        case .health: "Protected Apple Health connection"
        case .personalize: "Personal settings"
        case .ready: "Ready to begin"
        }
    }

    private func icon(_ name: String, tint: Color, size: CGFloat) -> some View {
        Image(systemName: name)
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(tint)
    }

    private func bar(height: CGFloat, tint: Color) -> some View {
        Capsule()
            .fill(tint)
            .frame(width: 18, height: height)
    }
}
