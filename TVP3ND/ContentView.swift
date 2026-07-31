import SwiftUI
import WebKit

struct ContentView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @StateObject private var browser = BrowserState()

    var body: some View {
        ZStack(alignment: .bottom) {
            if browser.isClosed {
                VStack(spacing: 16) {
                    Image(systemName: "tv.slash").font(.system(size: 46)).foregroundStyle(.cyan)
                    Text("تم إغلاق المشغل").font(.title3.bold())
                    Button("فتح التطبيق") { browser.reopen() }.buttonStyle(.borderedProminent)
                }
            } else {
                TVWebView(state: browser)
                    .ignoresSafeArea(edges: .top)
            }

            if !browser.isClosed {
                HStack(spacing: 12) {
                    actionButton("chevron.right", "رجوع") { browser.goBack() }
                    actionButton("chevron.left", "التالي") { browser.goForward() }
                    actionButton("house.fill", "الرئيسية") { browser.goHome() }
                    actionButton("xmark", "إغلاق") { browser.close() }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.bottom, 18)
                .zIndex(1)
            }

            if browser.isLoading && !browser.isClosed {
                LoadingView()
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .animation(.easeOut(duration: 0.25), value: browser.isLoading)
        .environment(\.layoutDirection, .rightToLeft)
        .sheet(isPresented: Binding(get: { !hasSeenWelcome }, set: { if !$0 { hasSeenWelcome = true } })) {
            WelcomeView(onStart: { hasSeenWelcome = true })
                .presentationDetents([.medium])
                .interactiveDismissDisabled()
        }
    }

    private func actionButton(_ icon: String, _ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .semibold))
                .labelStyle(.iconOnly)
                .frame(width: 42, height: 42)
        }
        .tint(.white)
        .accessibilityLabel(title)
    }
}

private struct LoadingView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.02, green: 0.05, blue: 0.11), Color(red: 0.05, green: 0.12, blue: 0.22)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(.cyan.opacity(0.14))
                        .frame(width: 112, height: 112)
                    Image(systemName: "tv.inset.filled")
                        .font(.system(size: 46, weight: .medium))
                        .foregroundStyle(.cyan)
                }

                Text("TV P3ND")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                ProgressView()
                    .tint(.cyan)
                    .scaleEffect(1.25)

                Text("جاري التحميل…")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.82))
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}

private struct WelcomeView: View {
    let onStart: () -> Void
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "tv.inset.filled")
                .font(.system(size: 50))
                .foregroundStyle(.cyan)
            Text("مرحبًا بك في TV P3ND")
                .font(.title2.bold())
            Text("استمتع بمشاهدة القنوات بسهولة. اسحب داخل الموقع للتصفح، ودوّر الشاشة لملء المشغل.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("دخول") { onStart() }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .controlSize(.large)
        }
        .padding(30)
        .environment(\.layoutDirection, .rightToLeft)
    }
}
